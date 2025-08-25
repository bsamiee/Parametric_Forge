//! Ultra-compact ring buffer history with const generics and spatial navigation
use arrayvec::ArrayVec; use compact_str::CompactString; use std::marker::PhantomData;
use crate::functionality::core::geometry::{SpatialEngine, Direction}; use bitflags::bitflags;
pub struct HistorySpace;
bitflags! { #[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default)] pub struct HistoryFlags: u8 {
    const WRAP = 1 << 0; const SEARCH = 1 << 1; const COMPRESS = 1 << 2; const PERSIST = 1 << 3; } }

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HistoryEngine<const N: usize = 32, S = HistorySpace> {
    entries: ArrayVec<CompactString, N>, spatial: SpatialEngine<u16>, 
    current: usize, flags: HistoryFlags, _space: PhantomData<S>, }

impl<const N: usize, S> HistoryEngine<N, S> {
    pub fn new(entries: ArrayVec<CompactString, N>, spatial: SpatialEngine<u16>, current: usize, 
               flags: HistoryFlags, _space: PhantomData<S>) -> Self {
        Self { entries, spatial, current, flags, _space } }
    pub fn add(&mut self, entry: impl Into<CompactString>) -> bool {
        let entry = entry.into(); if self.entries.is_full() { self.entries.remove(0); }
        self.entries.push(entry); self.current = self.entries.len().saturating_sub(1);
        self.spatial.max_items = self.entries.len() as u16; true }
    pub fn navigate(&mut self, direction: Direction) -> Option<&CompactString> {
        if self.entries.is_empty() { return None; }
        let new_pos = self.spatial.calculate_position(self.current as u16, direction) as usize;
        self.current = if self.flags.contains(HistoryFlags::WRAP) { new_pos % self.entries.len() } 
                      else { new_pos.min(self.entries.len().saturating_sub(1)) };
        Some(&self.entries[self.current]) }
    pub fn search(&self, pattern: &str) -> Option<usize> {
        if !self.flags.contains(HistoryFlags::SEARCH) || pattern.is_empty() { return None; }
        self.entries.iter().position(|entry| entry.contains(pattern)) }
    pub fn current(&self) -> Option<&CompactString> { self.entries.get(self.current) }
    pub fn jump_to(&mut self, index: usize) -> Option<&CompactString> {
        self.current = index.min(self.entries.len().saturating_sub(1)); self.current() }
    pub fn len(&self) -> usize { self.entries.len() }
    pub fn is_empty(&self) -> bool { self.entries.is_empty() }
    pub fn clear(&mut self) { self.entries.clear(); self.current = 0; self.spatial.max_items = 0; }
    pub fn up(&mut self) -> Option<&CompactString> { self.navigate(Direction::Up) }
    pub fn down(&mut self) -> Option<&CompactString> { self.navigate(Direction::Down) }
    pub fn home(&mut self) -> Option<&CompactString> { self.navigate(Direction::Home) }
    pub fn end(&mut self) -> Option<&CompactString> { self.navigate(Direction::End) }
    pub fn position(&self) -> usize { self.current } pub fn capacity(&self) -> usize { N }
    pub fn remaining(&self) -> usize { N - self.entries.len() }
    pub fn with_flags(mut self, flags: HistoryFlags) -> Self { self.flags = flags; self }
    pub fn prev(&mut self) -> Option<&CompactString> { if self.current > 0 { self.current -= 1; } self.current() }
    pub fn next(&mut self) -> Option<&CompactString> { 
        if self.current < self.entries.len().saturating_sub(1) { self.current += 1; } self.current() }
}

impl<const N: usize, S> Default for HistoryEngine<N, S> {
    fn default() -> Self { Self::new(ArrayVec::new(), SpatialEngine::linear().with_caching(), 0, 
                                     HistoryFlags::WRAP | HistoryFlags::SEARCH, PhantomData) } }
impl<const N: usize, S> std::fmt::Display for HistoryEngine<N, S> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "History[{}/{}]", self.current, self.entries.len()) } }
impl<const N: usize, S> std::ops::Deref for HistoryEngine<N, S> {
    type Target = ArrayVec<CompactString, N>; fn deref(&self) -> &Self::Target { &self.entries } }
impl<const N: usize, S> std::ops::DerefMut for HistoryEngine<N, S> {
    fn deref_mut(&mut self) -> &mut Self::Target { &mut self.entries } }
impl<const N: usize, S> std::ops::Index<usize> for HistoryEngine<N, S> {
    type Output = CompactString; fn index(&self, idx: usize) -> &Self::Output { &self.entries[idx] } }
impl<const N: usize, S> std::ops::IndexMut<usize> for HistoryEngine<N, S> {
    fn index_mut(&mut self, idx: usize) -> &mut Self::Output { &mut self.entries[idx] } }