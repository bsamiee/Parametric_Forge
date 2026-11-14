use std::{collections::BTreeMap, convert::Infallible, fmt, ops::Range};

use anstyle::{Color, Effects, Reset, RgbColor, Style};
use unicode_width::UnicodeWidthStr;
use zellij_tile::prelude::{AttentionCounts, AttentionStatus, InputMode, TabInfo};

// --- [TYPES] ---------------------------------------------------------------------------

trait Field: Copy + 'static {
    const NAMES: &'static [(&'static str, Self)];
}

#[derive(Debug, Clone, Copy)]
enum BarField {
    Tabs,
    SwapLayout,
    Session,
    Mode,
    Attention,
}

#[derive(Debug, Clone, Copy)]
enum TabField {
    Index,
    Name,
    Attention,
}

#[derive(Debug, Clone, Copy)]
enum NameField {
    Name,
}

#[derive(Debug, Clone, Copy)]
enum CountField {
    Count,
    Symbol,
}

#[derive(Debug, Clone, Copy)]
enum StatesField {
    States,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
enum Part {
    Left,
    Center,
    Right,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Click {
    Tab(usize),
    SwapLayout,
    Attention,
}

impl Field for BarField {
    const NAMES: &'static [(&'static str, Self)] = &[
        ("tabs", Self::Tabs),
        ("swap_layout", Self::SwapLayout),
        ("session", Self::Session),
        ("mode", Self::Mode),
        ("attention", Self::Attention),
    ];
}

impl Field for TabField {
    const NAMES: &'static [(&'static str, Self)] =
        &[("index", Self::Index), ("name", Self::Name), ("attention", Self::Attention)];
}

impl Field for NameField {
    const NAMES: &'static [(&'static str, Self)] = &[("name", Self::Name)];
}

impl Field for CountField {
    const NAMES: &'static [(&'static str, Self)] = &[("count", Self::Count), ("symbol", Self::Symbol)];
}

impl Field for StatesField {
    const NAMES: &'static [(&'static str, Self)] = &[("states", Self::States)];
}

impl Field for Infallible {
    const NAMES: &'static [(&'static str, Self)] = &[];
}

// --- [CONSTANTS] -----------------------------------------------------------------------

const EFFECTS: &[(&str, Effects)] = &[
    ("bold", Effects::BOLD),
    ("dim", Effects::DIMMED),
    ("italic", Effects::ITALIC),
    ("underscore", Effects::UNDERLINE),
    ("double-underscore", Effects::DOUBLE_UNDERLINE),
    ("curly-underscore", Effects::CURLY_UNDERLINE),
    ("dotted-underscore", Effects::DOTTED_UNDERLINE),
    ("dashed-underscore", Effects::DASHED_UNDERLINE),
    ("blink", Effects::BLINK),
    ("reverse", Effects::INVERT),
    ("hidden", Effects::HIDDEN),
    ("strikethrough", Effects::STRIKETHROUGH),
];

// --- [MODELS] --------------------------------------------------------------------------

#[derive(Debug)]
enum Token<F> {
    Text(String),
    Field(F),
}

#[derive(Debug)]
struct Piece<F> {
    style: Style,
    tokens: Vec<Token<F>>,
}

type Format<F> = Vec<Piece<F>>;

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Line {
    runs: Vec<(Style, String)>,
    width: usize,
    hits: Vec<(Range<usize>, Click)>,
}

impl Line {
    fn push(&mut self, style: Style, text: &str) {
        if text.is_empty() {
            return;
        }
        self.width += text.width();
        match self.runs.last_mut() {
            Some((last, run)) if *last == style => run.push_str(text),
            _ => self.runs.push((style, text.to_owned())),
        }
    }

    fn clicked(&mut self, click: Click, draw: impl FnOnce(&mut Self)) {
        let start = self.width;
        draw(self);
        if self.width > start {
            self.hits.push((start..self.width, click));
        }
    }

    pub fn hit(&self, column: usize) -> Option<Click> {
        self.hits.iter().find_map(|(range, click)| range.contains(&column).then_some(*click))
    }

    pub fn ansi(&self) -> impl fmt::Display {
        fmt::from_fn(|out| {
            self.runs.iter().try_for_each(|(style, run)| write!(out, "{}{}{run}", Reset.render(), style.render()))?;
            write!(out, "{}", Reset.render())
        })
    }

    fn append(&mut self, other: &Self) {
        let offset = self.width;
        self.hits.extend(other.hits.iter().map(|(range, click)| (range.start + offset..range.end + offset, *click)));
        other.runs.iter().for_each(|(style, text)| self.push(*style, text));
    }
}

#[derive(Debug, Clone, Copy)]
pub struct View<'a> {
    pub mode: InputMode,
    pub session: Option<&'a str>,
    pub tabs: &'a [TabInfo],
    pub attention: &'a AttentionCounts,
}

#[derive(Debug)]
pub struct Bar {
    parts: [Format<BarField>; 3],
    space: Style,
    precedence: [Part; 3],
    tab_active: Format<TabField>,
    tab_normal: Format<TabField>,
    tab_rename: Format<TabField>,
    tab_separator: Format<Infallible>,
    tab_attention: BTreeMap<AttentionStatus, Format<CountField>>,
    swap_layout: Format<NameField>,
    swap_layout_hide_if_empty: bool,
    modes: BTreeMap<InputMode, Format<Infallible>>,
    attention: Format<StatesField>,
    attention_separator: Format<Infallible>,
    attention_states: BTreeMap<AttentionStatus, Format<CountField>>,
    errors: Vec<ConfigError>,
}

impl Default for Bar {
    fn default() -> Self {
        Self::new(&BTreeMap::new())
    }
}

impl Bar {
    pub fn new(configuration: &BTreeMap<String, String>) -> Self {
        let mut bar = Self {
            parts: [Vec::new(), Vec::new(), Vec::new()],
            space: Style::new(),
            precedence: [Part::Left, Part::Center, Part::Right],
            tab_active: Vec::new(),
            tab_normal: Vec::new(),
            tab_rename: Vec::new(),
            tab_separator: Vec::new(),
            tab_attention: BTreeMap::new(),
            swap_layout: vec![Piece { style: Style::new(), tokens: vec![Token::Field(NameField::Name)] }],
            swap_layout_hide_if_empty: false,
            modes: BTreeMap::new(),
            attention: vec![Piece { style: Style::new(), tokens: vec![Token::Field(StatesField::States)] }],
            attention_separator: Vec::new(),
            attention_states: BTreeMap::new(),
            errors: Vec::new(),
        };
        let errors = configuration
            .iter()
            .filter_map(|(key, value)| bar.set(configuration, key, value).err())
            .flatten()
            .collect();
        Self { errors, ..bar }
    }

    fn set(&mut self, configuration: &BTreeMap<String, String>, key: &str, value: &str) -> Result<(), Vec<ConfigError>> {
        let read = |key: &str| ConfigError::Value { key: key.to_owned(), value: value.to_owned() };
        match key {
            "format_left" => self.parts[Part::Left as usize] = format(configuration, key, value)?,
            "format_center" => self.parts[Part::Center as usize] = format(configuration, key, value)?,
            "format_right" => self.parts[Part::Right as usize] = format(configuration, key, value)?,
            "format_space" => {
                self.space = format::<Infallible>(configuration, key, value)?.last().map_or_else(Style::new, |piece| piece.style);
            },
            "format_precedence" => self.precedence = precedence(value).ok_or_else(|| vec![read(key)])?,
            "tab_active" => self.tab_active = format(configuration, key, value)?,
            "tab_normal" => self.tab_normal = format(configuration, key, value)?,
            "tab_rename" => self.tab_rename = format(configuration, key, value)?,
            "tab_separator" => self.tab_separator = format(configuration, key, value)?,
            "swap_layout_format" => self.swap_layout = format(configuration, key, value)?,
            "swap_layout_hide_if_empty" => self.swap_layout_hide_if_empty = value.parse().map_err(|_| vec![read(key)])?,
            "attention_format" => self.attention = format(configuration, key, value)?,
            "attention_separator" => self.attention_separator = format(configuration, key, value)?,
            "caller_cwd" => {},
            _ => match (
                key.strip_prefix("color_"),
                key.strip_prefix("mode_"),
                key.strip_prefix("tab_attention_").and_then(AttentionStatus::from_str),
                key.strip_prefix("attention_").and_then(AttentionStatus::from_str),
            ) {
                (Some(_), _, _, _) => {},
                (_, Some(mode), _, _) => {
                    let mode = mode.parse::<InputMode>().map_err(|_| vec![ConfigError::Key { key: key.to_owned() }])?;
                    self.modes.insert(mode, format(configuration, key, value)?);
                },
                (_, _, Some(status), _) => {
                    self.tab_attention.insert(status, format(configuration, key, value)?);
                },
                (_, _, _, Some(status)) => {
                    self.attention_states.insert(status, format(configuration, key, value)?);
                },
                (None, None, None, None) => return Err(vec![ConfigError::Key { key: key.to_owned() }]),
            },
        }
        Ok(())
    }
}

// --- [ERRORS] --------------------------------------------------------------------------

#[derive(Debug, Clone, thiserror::Error)]
pub enum ConfigError {
    #[error("{key}: no such option")]
    Key { key: String },
    #[error("{key}: unreadable value {value}")]
    Value { key: String, value: String },
    #[error("{key}: no color {color}")]
    Color { key: String, color: String },
    #[error("{key}: no style {style}")]
    Style { key: String, style: String },
    #[error("{key}: no field {{{field}}}")]
    Field { key: String, field: String },
}

// --- [OPERATIONS] ----------------------------------------------------------------------

fn all<T>(items: impl IntoIterator<Item = Result<T, Vec<ConfigError>>>) -> Result<Vec<T>, Vec<ConfigError>> {
    let (values, errors): (Vec<T>, Vec<Vec<ConfigError>>) =
        items.into_iter().fold((Vec::new(), Vec::new()), |(mut values, mut errors), item| {
            match item {
                Ok(value) => values.push(value),
                Err(refused) => errors.push(refused),
            }
            (values, errors)
        });
    errors.is_empty().then_some(values).ok_or_else(|| errors.concat())
}

fn precedence(value: &str) -> Option<[Part; 3]> {
    let parts = value
        .chars()
        .map(|part| match part {
            'l' => Some(Part::Left),
            'c' => Some(Part::Center),
            'r' => Some(Part::Right),
            _ => None,
        })
        .collect::<Option<Vec<Part>>>()?;
    <[Part; 3]>::try_from(parts).ok().filter(|[a, b, c]| a != b && b != c && a != c)
}

fn color(configuration: &BTreeMap<String, String>, key: &str, name: &str) -> Result<Color, Vec<ConfigError>> {
    name.strip_prefix('$')
        .map_or(Some(name), |alias| configuration.get(&format!("color_{alias}")).map(String::as_str))
        .and_then(|hex| hex.strip_prefix('#'))
        .filter(|hex| hex.len() == 6)
        .and_then(|hex| u32::from_str_radix(hex, 16).ok())
        .map(|rgb| match rgb.to_be_bytes() {
            [_, red, green, blue] => Color::Rgb(RgbColor(red, green, blue)),
        })
        .ok_or_else(|| vec![ConfigError::Color { key: key.to_owned(), color: name.to_owned() }])
}

fn style(configuration: &BTreeMap<String, String>, key: &str, spec: &str) -> Result<Style, Vec<ConfigError>> {
    all(spec.split(',').map(|item| match item.split_once('=') {
        Some(("fg", name)) => color(configuration, key, name).map(|color| Style::new().fg_color(Some(color))),
        Some(("bg", name)) => color(configuration, key, name).map(|color| Style::new().bg_color(Some(color))),
        Some(("us", name)) => color(configuration, key, name).map(|color| Style::new().underline_color(Some(color))),
        _ => EFFECTS
            .iter()
            .find(|(effect, _)| *effect == item)
            .map(|(_, effects)| Style::new().effects(*effects))
            .ok_or_else(|| vec![ConfigError::Style { key: key.to_owned(), style: item.to_owned() }]),
    }))
    .map(|styles| styles.into_iter().fold(Style::new(), |held, next| over(next, held)))
}

fn tokens<F: Field>(key: &str, text: &str) -> Result<Vec<Token<F>>, Vec<ConfigError>> {
    let mut segments = text.split('{');
    let head = segments.next().filter(|head| !head.is_empty()).map(|head| Ok(Token::Text(head.to_owned())));
    all(head.into_iter().chain(segments.flat_map(|segment| match segment.split_once('}') {
        Some((name, rest)) => [
            Some(
                F::NAMES
                    .iter()
                    .find(|(field, _)| *field == name)
                    .map(|(_, field)| Token::Field(*field))
                    .ok_or_else(|| vec![ConfigError::Field { key: key.to_owned(), field: name.to_owned() }]),
            ),
            (!rest.is_empty()).then(|| Ok(Token::Text(rest.to_owned()))),
        ],
        None => [Some(Ok(Token::Text(format!("{{{segment}")))), None],
    })
    .flatten()))
}

fn format<F: Field>(configuration: &BTreeMap<String, String>, key: &str, value: &str) -> Result<Format<F>, Vec<ConfigError>> {
    all(value.split("#[").enumerate().map(|(index, chunk)| match (index, chunk.split_once(']')) {
        (0, _) => tokens(key, chunk).map(|tokens| Piece { style: Style::new(), tokens }),
        (_, Some((spec, text))) => match (style(configuration, key, spec), tokens(key, text)) {
            (Ok(style), Ok(tokens)) => Ok(Piece { style, tokens }),
            (style, tokens) => Err(style.err().into_iter().chain(tokens.err()).flatten().collect()),
        },
        (_, None) => Err(vec![ConfigError::Style { key: key.to_owned(), style: chunk.to_owned() }]),
    }))
}

fn over(inner: Style, outer: Style) -> Style {
    inner
        .fg_color(inner.get_fg_color().or_else(|| outer.get_fg_color()))
        .bg_color(inner.get_bg_color().or_else(|| outer.get_bg_color()))
        .underline_color(inner.get_underline_color().or_else(|| outer.get_underline_color()))
        .effects(inner.get_effects() | outer.get_effects())
}

fn emit<F: Copy>(line: &mut Line, format: &Format<F>, outer: Style, field: &mut impl FnMut(&mut Line, F, Style)) {
    for piece in format {
        let style = over(piece.style, outer);
        for token in &piece.tokens {
            match token {
                Token::Text(text) => line.push(style, text),
                Token::Field(name) => field(line, *name, style),
            }
        }
    }
}

fn plain(line: &mut Line, format: &Format<Infallible>, style: Style) {
    emit(line, format, style, &mut |_, never, _| match never {});
}

fn counted(line: &mut Line, format: &Format<CountField>, style: Style, status: AttentionStatus, counts: &AttentionCounts) {
    emit(line, format, style, &mut |line, field, style| match field {
        CountField::Count => line.push(style, &counts.of(status).to_string()),
        CountField::Symbol => line.push(style, status.symbol()),
    });
}

fn tab(bar: &Bar, view: View<'_>, line: &mut Line, tab: &TabInfo, style: Style) {
    let renaming = view.mode == InputMode::RenameTab;
    let format = [(tab.active && renaming, &bar.tab_rename), (tab.active, &bar.tab_active)]
        .into_iter()
        .find(|(chosen, format)| *chosen && !format.is_empty())
        .map_or(&bar.tab_normal, |(_, format)| format);
    let marker = bar.tab_attention.get(&tab.attention.status).filter(|_| !tab.attention.muted);
    line.clicked(Click::Tab(tab.position), |line| {
        emit(line, format, style, &mut |line, field, style| match field {
            TabField::Index => line.push(style, &(tab.position + 1).to_string()),
            TabField::Name if renaming && tab.name.is_empty() => line.push(style, "Enter name..."),
            TabField::Name => line.push(style, &tab.name),
            TabField::Attention => {
                if let Some(marker) = marker {
                    counted(line, marker, style, tab.attention.status, &tab.attention.counts);
                }
            },
        });
    });
}

fn widget(bar: &Bar, view: View<'_>, line: &mut Line, field: BarField, style: Style) {
    match field {
        BarField::Tabs => view.tabs.iter().enumerate().for_each(|(index, info)| {
            if index > 0 {
                plain(line, &bar.tab_separator, style);
            }
            tab(bar, view, line, info, style);
        }),
        BarField::SwapLayout => {
            let name = view.tabs.iter().find(|info| info.active).map(|info| info.active_swap_layout_name.as_deref().unwrap_or_default());
            if let Some(name) = name.filter(|name| !(name.is_empty() && bar.swap_layout_hide_if_empty)) {
                line.clicked(Click::SwapLayout, |line| {
                    emit(line, &bar.swap_layout, style, &mut |line, NameField::Name, style| line.push(style, name));
                });
            }
        },
        BarField::Session => line.push(style, view.session.unwrap_or_default()),
        BarField::Mode => {
            if let Some(format) = bar.modes.get(&view.mode).or_else(|| bar.modes.get(&InputMode::Normal)) {
                plain(line, format, style);
            }
        },
        BarField::Attention => {
            let states: Vec<(AttentionStatus, &Format<CountField>)> = bar
                .attention_states
                .iter()
                .rev()
                .filter(|(status, _)| view.attention.of(**status) > 0)
                .map(|(status, format)| (*status, format))
                .collect();
            if !states.is_empty() {
                line.clicked(Click::Attention, |line| {
                    emit(line, &bar.attention, style, &mut |line, StatesField::States, style| {
                        states.iter().enumerate().for_each(|(index, (status, format))| {
                            if index > 0 {
                                plain(line, &bar.attention_separator, style);
                            }
                            counted(line, format, style, *status, view.attention);
                        });
                    });
                });
            }
        },
    }
}

pub fn parts(bar: &Bar, view: View<'_>) -> [Line; 3] {
    match bar.errors.as_slice() {
        [] => bar.parts.each_ref().map(|format| {
            let mut line = Line::default();
            emit(&mut line, format, Style::new(), &mut |line, field, style| widget(bar, view, line, field, style));
            line
        }),
        errors => {
            let mut line = Line::default();
            for error in errors {
                line.push(Style::new(), &format!("statusbar: {error}  "));
            }
            [line, Line::default(), Line::default()]
        },
    }
}

pub fn layout(bar: &Bar, parts: &[Line; 3], cols: usize) -> Line {
    let collides = |widths: [usize; 3], a: Part, b: Part| {
        let [left, center, right] = widths;
        let start = (cols / 2).saturating_sub(center / 2);
        match (a.min(b), a.max(b)) {
            (Part::Left, Part::Right) => left + right > cols,
            (Part::Left, Part::Center) => center > 0 && left > start,
            (Part::Center, Part::Right) => center > 0 && start + center > cols.saturating_sub(right),
            _ => false,
        }
    };
    let [first, second, third] = bar.precedence;
    let shown = [(third, second), (second, first), (third, first)].into_iter().fold(
        parts.each_ref().map(|line| line.width),
        |mut widths, (a, b)| {
            if collides(widths, a, b) {
                widths[a as usize] = 0;
            }
            widths
        },
    );
    let [left, center, right] = shown;
    let (pad_left, pad_right) = match center {
        0 => (cols.saturating_sub(left + right), 0),
        _ => ((cols / 2).saturating_sub(left + center / 2), cols.div_ceil(2).saturating_sub(right + center.div_ceil(2))),
    };
    let mut out = Line::default();
    let mut draw = |part: Part, pad: usize| {
        if shown[part as usize] > 0 {
            out.append(&parts[part as usize]);
        }
        out.push(bar.space, &" ".repeat(pad));
    };
    draw(Part::Left, pad_left);
    draw(Part::Center, pad_right);
    draw(Part::Right, 0);
    let clipped = out.runs.iter().fold(Line { hits: out.hits.clone(), ..Line::default() }, |mut clipped, (style, text)| {
        let room = cols.saturating_sub(clipped.width);
        let kept = text
            .char_indices()
            .map(|(at, glyph)| at + glyph.len_utf8())
            .take_while(|end| text[..*end].width() <= room)
            .last()
            .unwrap_or(0);
        clipped.push(*style, &text[..kept]);
        clipped
    });
    Line { hits: clipped.hits.iter().filter(|(range, _)| range.start < cols).cloned().collect(), ..clipped }
}
