// Title         : widgets/validation.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/widgets/validation.rs
// ----------------------------------------------------------------------------

//! Consolidated validation module for all widget input validation

use color_eyre::eyre::Result;

// --- Validation Error Macro ------------------------------------------------

/// Macro for consistent error creation throughout validation system
macro_rules! validation_error {
    ($msg:literal) => {
        color_eyre::eyre::eyre!($msg)
    };
    ($fmt:literal, $($arg:expr),*) => {
        color_eyre::eyre::eyre!($fmt, $($arg),*)
    };
}

// --- Core Validation Trait --------------------------------------------------

/// Validation trait for input widgets with empty-aware support
pub trait Validator<T>: Send {
    fn validate(&self, value: &T) -> Result<()>;

    /// Get a user-friendly error message for validation failures
    fn error_message(&self, value: &T) -> String {
        match self.validate(value) {
            Ok(_) => String::new(),
            Err(e) => e.to_string(),
        }
    }
}

/// Trait for validators that handle empty values consistently
pub trait EmptyAware {
    fn is_empty(&self, value: &String) -> bool {
        value.trim().is_empty()
    }

    fn handle_empty(&self) -> Result<()> {
        Ok(())
    }
}

// --- Generic Bounds Validator ----------------------------------------------

/// Generic bounds validator for any comparable type
pub struct BoundsValidator<T: PartialOrd + Copy + std::fmt::Display> {
    min: Option<T>,
    max: Option<T>,
    unit: &'static str,
}

impl<T: PartialOrd + Copy + std::fmt::Display> BoundsValidator<T> {
    pub fn new(min: Option<T>, max: Option<T>, unit: &'static str) -> Self {
        Self { min, max, unit }
    }

    pub fn min(min: T, unit: &'static str) -> Self {
        Self::new(Some(min), None, unit)
    }

    pub fn max(max: T, unit: &'static str) -> Self {
        Self::new(None, Some(max), unit)
    }

    pub fn range(min: T, max: T, unit: &'static str) -> Self {
        Self::new(Some(min), Some(max), unit)
    }

    fn validate_bounds(&self, value: T) -> Result<()> {
        if let Some(min) = self.min {
            if value < min {
                return Err(validation_error!("Value must be at least {} {}", min, self.unit));
            }
        }
        if let Some(max) = self.max {
            if value > max {
                return Err(validation_error!("Value must be at most {} {}", max, self.unit));
            }
        }
        Ok(())
    }
}

/// Type aliases for common bounds validators
pub type LengthValidator = BoundsValidator<usize>;
pub type RangeValidator = BoundsValidator<f64>;

// --- Specialized Implementations --------------------------------------------

impl Validator<String> for LengthValidator {
    fn validate(&self, value: &String) -> Result<()> {
        self.validate_bounds(value.len())
    }
}

impl EmptyAware for LengthValidator {}

impl Validator<String> for RangeValidator {
    fn validate(&self, value: &String) -> Result<()> {
        if self.is_empty(value) {
            return self.handle_empty();
        }

        let num: f64 = value.parse().map_err(|_| validation_error!("Value must be a number"))?;

        self.validate_bounds(num)
    }
}

impl EmptyAware for RangeValidator {}

// --- Simple Validators ------------------------------------------------------

/// Required field validator
pub struct RequiredValidator;

impl Validator<String> for RequiredValidator {
    fn validate(&self, value: &String) -> Result<()> {
        if value.trim().is_empty() {
            return Err(validation_error!("This field is required"));
        }
        Ok(())
    }
}

// --- Macro-Generated Simple Validators -------------------------------------

/// Macro to generate simple validators with consistent empty handling
macro_rules! simple_validator {
    ($name:ident, $check:expr, $error:literal) => {
        pub struct $name;

        impl Validator<String> for $name {
            fn validate(&self, value: &String) -> Result<()> {
                if self.is_empty(value) {
                    return self.handle_empty();
                }

                if !($check)(value) {
                    return Err(validation_error!($error));
                }

                Ok(())
            }
        }

        impl EmptyAware for $name {}
    };
}

// Generate validators using the macro
simple_validator!(
    NumericValidator,
    |v: &String| v.parse::<f64>().is_ok(),
    "Input must be a valid number"
);

simple_validator!(
    EmailValidator,
    |v: &String| {
        v.contains('@') && v.contains('.') && {
            let parts: Vec<&str> = v.split('@').collect();
            parts.len() == 2 && !parts[0].is_empty() && !parts[1].is_empty()
        }
    },
    "Please enter a valid email address"
);

simple_validator!(
    UrlValidator,
    |v: &String| { v.starts_with("http://") || v.starts_with("https://") },
    "URL must start with http:// or https://"
);

// Range validator is now an alias defined above with BoundsValidator<f64>

/// Generic pattern validator with const pattern matching
pub struct PatternValidator {
    pattern_type: PatternType,
    message: &'static str,
}

#[derive(Debug, Clone, Copy)]
enum PatternType {
    Alphanumeric,
    FilePath,
    Custom(&'static str),
}

impl PatternValidator {
    pub fn new(pattern: &'static str, message: &'static str) -> Self {
        Self {
            pattern_type: PatternType::Custom(pattern),
            message,
        }
    }

    pub fn alphanumeric() -> Self {
        Self {
            pattern_type: PatternType::Alphanumeric,
            message: "Only letters and numbers are allowed",
        }
    }

    pub fn file_path() -> Self {
        Self {
            pattern_type: PatternType::FilePath,
            message: "Please enter a valid file path",
        }
    }
}

impl Validator<String> for PatternValidator {
    fn validate(&self, value: &String) -> Result<()> {
        if self.is_empty(value) {
            return self.handle_empty();
        }

        let is_valid = match self.pattern_type {
            PatternType::Alphanumeric => value.chars().all(|c| c.is_alphanumeric()),
            PatternType::FilePath => !value.contains("..") && !(value.starts_with('/') && value.len() == 1),
            PatternType::Custom(_) => true, // Custom patterns could be enhanced with regex
        };

        if !is_valid {
            return Err(validation_error!("{}", self.message));
        }

        Ok(())
    }
}

impl EmptyAware for PatternValidator {}

// --- Composite Validators ---------------------------------------------------

/// Custom validator that can trigger specific actions
pub struct ActionValidator {
    validator: Box<dyn Validator<String>>,
    error_action: Option<crate::core::Action>,
    success_action: Option<crate::core::Action>,
}

impl ActionValidator {
    pub fn new<V: Validator<String> + 'static>(validator: V) -> Self {
        Self {
            validator: Box::new(validator),
            error_action: None,
            success_action: None,
        }
    }

    pub fn with_error_action(mut self, action: crate::core::Action) -> Self {
        self.error_action = Some(action);
        self
    }

    pub fn with_success_action(mut self, action: crate::core::Action) -> Self {
        self.success_action = Some(action);
        self
    }

    pub fn error_action(&self) -> Option<&crate::core::Action> {
        self.error_action.as_ref()
    }

    pub fn success_action(&self) -> Option<&crate::core::Action> {
        self.success_action.as_ref()
    }
}

impl Validator<String> for ActionValidator {
    fn validate(&self, value: &String) -> Result<()> {
        self.validator.validate(value)
    }
}

/// Conditional validator that only validates under certain conditions
pub struct ConditionalValidator<F>
where
    F: Fn() -> bool + Send,
{
    validator: Box<dyn Validator<String>>,
    condition: F,
}

impl<F> ConditionalValidator<F>
where
    F: Fn() -> bool + Send,
{
    pub fn new<V: Validator<String> + 'static>(validator: V, condition: F) -> Self {
        Self {
            validator: Box::new(validator),
            condition,
        }
    }
}

impl<F> Validator<String> for ConditionalValidator<F>
where
    F: Fn() -> bool + Send,
{
    fn validate(&self, value: &String) -> Result<()> {
        if (self.condition)() {
            self.validator.validate(value)
        } else {
            Ok(())
        }
    }
}

/// Composite validator that runs multiple validators
pub struct CompositeValidator {
    validators: Vec<Box<dyn Validator<String>>>,
    stop_on_first_error: bool,
}

impl CompositeValidator {
    pub fn new() -> Self {
        Self {
            validators: Vec::new(),
            stop_on_first_error: true,
        }
    }

    pub fn add_validator<V: Validator<String> + 'static>(mut self, validator: V) -> Self {
        self.validators.push(Box::new(validator));
        self
    }

    pub fn continue_on_error(mut self) -> Self {
        self.stop_on_first_error = false;
        self
    }
}

impl Default for CompositeValidator {
    fn default() -> Self {
        Self::new()
    }
}

impl Validator<String> for CompositeValidator {
    fn validate(&self, value: &String) -> Result<()> {
        let mut errors = Vec::new();

        for validator in &self.validators {
            if let Err(e) = validator.validate(value) {
                if self.stop_on_first_error {
                    return Err(e);
                } else {
                    errors.push(e.to_string());
                }
            }
        }

        if !errors.is_empty() {
            return Err(color_eyre::eyre::eyre!("Validation failed: {}", errors.join("; ")));
        }

        Ok(())
    }
}
