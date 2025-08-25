//! Ultra-compact validation system using validator crate + rayon parallelization

use validator::{Validate, ValidationError as ValidatorError};
use rayon::prelude::*;
use once_cell::sync::Lazy;
use rustc_hash::FxHashMap;
use derive_more::{Constructor, From, Into, Display, Deref, DerefMut};
use std::marker::PhantomData;

pub struct ValidationSpace;
pub type ValidatorFn = fn(&str) -> Result<(), ValidatorError>;

static RULES: Lazy<FxHashMap<&'static str, ValidatorFn>> = Lazy::new(|| [
    ("email", |s| validator::validate_email(s).then_some(()).ok_or_else(|| ValidatorError::new("invalid_email")) as Result<(), ValidatorError>),
    ("url", |s| validator::validate_url(s).then_some(()).ok_or_else(|| ValidatorError::new("invalid_url"))),
    ("length", |s| (s.len() >= 1 && s.len() <= 255).then_some(()).ok_or_else(|| ValidatorError::new("invalid_length"))),
    ("required", |s| (!s.trim().is_empty()).then_some(()).ok_or_else(|| ValidatorError::new("required"))),
].into_iter().collect());

#[derive(Debug, Clone, Copy, Constructor)]
pub struct ValidationEngine<S = ValidationSpace> {
    rules: &'static FxHashMap<&'static str, ValidatorFn>,
    parallel: bool,
    _space: PhantomData<S>,
}

impl<S> std::fmt::Display for ValidationEngine<S> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "ValidationEngine(parallel={})", self.parallel)
    }
}

// API compatibility types
#[derive(Debug, Clone)] 
pub enum ValidationBehavior { None, Single, Chain }
#[derive(Debug, Clone)] 
pub enum ValidationResult { Valid, Invalid(String) }

#[derive(Debug, Clone, Validate, Constructor, From, Into, Display, Deref, DerefMut)]
#[validate(schema(function = "validate_email_custom"))]
pub struct EmailField(String);

#[derive(Debug, Clone, Validate, Constructor, From, Into, Display, Deref, DerefMut)]
#[validate(schema(function = "validate_url_custom"))]
pub struct UrlField(String);

#[derive(Debug, Clone, Validate, Constructor, From, Into, Display, Deref, DerefMut)]
#[validate(length(min = 1, max = 255))]
pub struct TextField(String);

#[derive(Debug, Clone, Validate, Constructor, From, Into, Display, Deref, DerefMut)]
#[validate(length(min = 1), schema(function = "validate_required"))]
pub struct RequiredField(String);

impl<S> Default for ValidationEngine<S> {
    fn default() -> Self {
        Self::new(&RULES, true, PhantomData)
    }
}

impl<S> ValidationEngine<S> {
    pub fn validate_single(&self, field: &str, value: &str) -> Result<(), ValidatorError> {
        self.rules.get(field)
            .ok_or_else(|| ValidatorError::new("unknown_field"))?
            (value)
    }

    pub fn validate_batch(&self, items: &[(String, String)]) -> Vec<Result<(), ValidatorError>> {
        if self.parallel && items.len() > 10 {
            items.par_iter()
                .map(|(field, value)| self.validate_single(field, value))
                .collect()
        } else {
            items.iter()
                .map(|(field, value)| self.validate_single(field, value))
                .collect()
        }
    }
}

fn validate_email_custom(email: &str) -> Result<(), validator::ValidationError> { validator::validate_email(email).then_some(()).ok_or_else(|| validator::ValidationError::new("invalid_email")) }
fn validate_url_custom(url: &str) -> Result<(), validator::ValidationError> { validator::validate_url(url).then_some(()).ok_or_else(|| validator::ValidationError::new("invalid_url")) }
fn validate_required(value: &str) -> Result<(), validator::ValidationError> { (!value.trim().is_empty()).then_some(()).ok_or_else(|| validator::ValidationError::new("required")) }

pub mod presets {
    use super::*;
    pub fn email() -> EmailField { EmailField("".to_string()) }
    pub fn url() -> UrlField { UrlField("".to_string()) }
    pub fn text() -> TextField { TextField("".to_string()) }
    pub fn required() -> RequiredField { RequiredField("".to_string()) }
}