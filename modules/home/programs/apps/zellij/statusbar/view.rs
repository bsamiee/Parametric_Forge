use std::{
    fmt::{self, Write},
    ops::Range,
};

use anstyle::{Color, Effects, Reset, RgbColor, Style};
use unicode_width::{UnicodeWidthChar, UnicodeWidthStr};

// --- [TYPES] ---------------------------------------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum Count {
    Failed,
    Working,
    Idle,
    Command,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum Hit {
    Tab(usize),
    Notice,
    Count(Count),
    Session,
}

// --- [MODELS] --------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Line {
    runs: Vec<(Style, String)>,
    width: usize,
    hits: Vec<(Range<usize>, Hit)>,
}

impl Line {
    pub fn push(&mut self, style: Style, text: impl fmt::Display) -> &mut Self {
        let start = self.runs.last().is_none_or(|(last, _)| *last != style);
        if start {
            self.runs.push((style, String::new()));
        }
        if let Some((_, run)) = self.runs.last_mut() {
            let before = run.len();
            let _ = write!(run, "{text}");
            self.width += run[before..].width();
        }
        if self.runs.last().is_some_and(|(_, run)| run.is_empty()) {
            self.runs.pop();
        }
        self
    }

    pub fn gap(&mut self, cells: usize) -> &mut Self {
        self.push(Style::new(), format_args!("{:cells$}", ""))
    }

    pub fn hit(&mut self, hit: Hit, draw: impl FnOnce(&mut Self)) -> &mut Self {
        let start = self.width;
        draw(self);
        self.hits.push((start..self.width, hit));
        self
    }

    pub fn append(&mut self, other: &Self) -> &mut Self {
        let offset = self.width;
        self.hits.extend(other.hits.iter().map(|(range, hit)| (range.start + offset..range.end + offset, *hit)));
        other.runs.iter().for_each(|(style, text)| {
            self.push(*style, text);
        });
        self
    }

    pub fn ground(mut self, hex: u32) -> Self {
        self.runs.iter_mut().filter(|(style, _)| style.get_bg_color().is_none()).for_each(|(style, _)| *style = on(*style, hex));
        self
    }

    pub fn clip(self, cols: usize) -> Self {
        if self.width <= cols {
            return self;
        }
        let room = cols.saturating_sub(1);
        let mut out = Self { hits: self.hits.iter().filter(|(range, _)| range.end <= room).cloned().collect(), ..Self::default() };
        let mut last = Style::new();
        for (style, text) in &self.runs {
            let kept: String = text.chars().scan(out.width, |used, glyph| {
                *used += glyph.width().unwrap_or(0);
                (*used <= room).then_some(glyph)
            }).collect();
            last = *style;
            let full = kept.len() == text.len();
            out.push(*style, &kept);
            if !full {
                break;
            }
        }
        out.push(last, '…');
        out
    }

    pub const fn width(&self) -> usize {
        self.width
    }

    pub fn at(&self, column: usize) -> Option<Hit> {
        self.hits.iter().find_map(|(range, hit)| range.contains(&column).then_some(*hit))
    }

    pub fn ansi(&self) -> impl fmt::Display + '_ {
        fmt::from_fn(|out| {
            self.runs.iter().try_for_each(|(style, run)| write!(out, "{}{}{run}", Reset.render(), style.render()))?;
            write!(out, "{}", Reset.render())
        })
    }
}

// --- [OPERATIONS] ----------------------------------------------------------------------

pub const fn rgb(hex: u32) -> Color {
    let [_, red, green, blue] = hex.to_be_bytes();
    Color::Rgb(RgbColor(red, green, blue))
}

pub fn ink(hex: u32) -> Style {
    Style::new().fg_color(Some(rgb(hex)))
}

pub fn with(style: Style, effects: Effects) -> Style {
    style.effects(style.get_effects() | effects)
}

pub fn bold(style: Style) -> Style {
    with(style, Effects::BOLD)
}

pub fn on(style: Style, hex: u32) -> Style {
    style.bg_color(Some(rgb(hex)))
}

pub fn underline_if(style: Style, on: bool) -> Style {
    if on { with(style, Effects::DOTTED_UNDERLINE) } else { style }
}

pub fn compose(left: &Line, center: &Line, right: &Line, cols: usize, anchor: usize) -> Option<Line> {
    let free = cols.checked_sub(left.width + right.width)?;
    let lead = if center.width == 0 {
        free
    } else {
        let slack = free.checked_sub(center.width + 2)?;
        let anchored = anchor.checked_sub(left.width).filter(|lead| *lead >= 1 && lead + center.width < free);
        anchored.unwrap_or(slack / 2 + 1)
    };
    let mut out = left.clone();
    out.gap(lead).append(center).gap(free - lead - center.width).append(right);
    Some(out)
}
