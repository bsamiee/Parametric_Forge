//! Ultra-compact compile-time pattern masking engine
//! Author: Bardia Samiee <b.samiee93@gmail.com>
//! Project: Parametric Forge
//! License: MIT

use once_cell::sync::Lazy;
use rustc_hash::FxHashMap;
use compact_str::CompactString;
use arrayvec::ArrayVec;
use derive_more::{Constructor, From, Into, Display, Debug, Clone, Copy, Hash, PartialEq};
use std::marker::PhantomData;

pub trait MaskPattern { const PATTERN: &'static str; const PLACEHOLDER: char; fn transform(input: &str) -> CompactString { CompactString::from(input) } }

#[derive(Debug, Clone, Copy, Hash, PartialEq, Constructor, From, Into, Display)] pub struct PasswordMask;
#[derive(Debug, Clone, Copy, Hash, PartialEq, Constructor, From, Into, Display)] pub struct PhoneMask;
#[derive(Debug, Clone, Copy, Hash, PartialEq, Constructor, From, Into, Display)] pub struct CreditCardMask;
#[derive(Debug, Clone, Copy, Hash, PartialEq, Constructor, From, Into, Display)] pub struct SSNMask;

impl MaskPattern for PasswordMask { const PATTERN: &'static str = "*"; const PLACEHOLDER: char = '*'; fn transform(input: &str) -> CompactString { CompactString::from("*".repeat(input.chars().count())) } }
impl MaskPattern for PhoneMask { const PATTERN: &'static str = "(###) ###-####"; const PLACEHOLDER: char = '_'; }
impl MaskPattern for CreditCardMask { const PATTERN: &'static str = "#### #### #### ####"; const PLACEHOLDER: char = '_'; }
impl MaskPattern for SSNMask { const PATTERN: &'static str = "###-##-####"; const PLACEHOLDER: char = '_'; }

static CACHE: Lazy<FxHashMap<&'static str, fn(&str) -> MaskResult>> = Lazy::new(|| { let mut m = FxHashMap::default(); m.insert("*", |i| MaskResult { formatted: i.into(), display: "*".repeat(i.chars().count()).into(), valid: !i.is_empty() }); m.insert("(###) ###-####", |i| apply::<PhoneMask>(i)); m.insert("#### #### #### ####", |i| apply::<CreditCardMask>(i)); m.insert("###-##-####", |i| apply::<SSNMask>(i)); m });

#[derive(Debug, Clone, Copy, Constructor, From, Into, Hash, PartialEq)]
pub struct MaskEngine<M: MaskPattern>(PhantomData<M>, Option<u64>);

impl<M: MaskPattern> std::fmt::Display for MaskEngine<M> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "MaskEngine<{}>", M::PATTERN)
    }
}

#[derive(Debug, Clone, Constructor, From, Into, Hash, PartialEq)] 
pub struct MaskResult { pub formatted: CompactString, pub display: CompactString, pub valid: bool }

impl std::fmt::Display for MaskResult {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "MaskResult({})", self.display)
    }
}

fn apply<M: MaskPattern>(input: &str) -> MaskResult { let mut out = ArrayVec::<char, 32>::new(); let mut chars = input.chars(); for c in M::PATTERN.chars() { match c { '#' => out.push(chars.next().filter(|c| c.is_ascii_digit()).unwrap_or(M::PLACEHOLDER)), l => out.push(l) } } MaskResult { formatted: input.into(), display: out.iter().collect::<String>().into(), valid: !out.contains(&M::PLACEHOLDER) } }

pub fn mask<M: MaskPattern + 'static>(input: &str) -> MaskResult { CACHE.get(M::PATTERN).map_or_else(|| apply::<M>(input), |f| f(input)) }

impl<M: MaskPattern> MaskEngine<M> { pub fn apply(&self, input: &str) -> MaskResult { mask::<M>(input) } }

pub mod presets { use super::*; pub const PASSWORD: MaskEngine<PasswordMask> = MaskEngine::new(PhantomData, None); pub const PHONE: MaskEngine<PhoneMask> = MaskEngine::new(PhantomData, None); pub const CREDIT_CARD: MaskEngine<CreditCardMask> = MaskEngine::new(PhantomData, None); pub const SSN: MaskEngine<SSNMask> = MaskEngine::new(PhantomData, None); }