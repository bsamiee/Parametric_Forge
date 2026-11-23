mod view;

use std::{
    collections::{BTreeMap, BTreeSet},
    time::{Duration, Instant},
};

use anstyle::{Effects, Style};
use unicode_width::{UnicodeWidthChar, UnicodeWidthStr};
use zellij_tile::prelude::{actions::Action, *};

use crate::view::{Count, Hit, Line, bold, compose, ink, on, underline_if, with};

mod data {
    use zellij_tile::prelude::InputMode;

    pub struct Palette {
        pub surface: u32,
        pub fg: u32,
        pub muted: u32,
        pub subtle: u32,
        pub selected: u32,
        pub inverse: u32,
        pub focus: u32,
        pub session: u32,
        pub run: u32,
        pub idle: u32,
        pub need: u32,
        pub fail: u32,
    }

    pub struct Layer {
        pub mark: &'static str,
        pub color: u32,
        pub name: &'static str,
    }

    pub struct Group {
        pub layer: Option<&'static Layer>,
        pub joined: bool,
        pub hints: &'static [(&'static str, &'static str, bool)],
    }

    pub struct Ribbon {
        pub chip: &'static str,
        pub fill: u32,
        pub label: u32,
        pub note: &'static str,
        pub groups: &'static [Group],
        pub done: bool,
    }

    include!(env!("STATUSBAR_DATA"));
}

use data::{HYPER, NEXT_CHORD, NEXT_KEY, NEXT_MODES, PALETTE as P, SUPER, ribbon};

// --- [CONSTANTS] -----------------------------------------------------------------------

const HOVER: Duration = Duration::from_secs(10);
const LABEL_COLS: usize = 24;
const SESSION_COLS: usize = 12;
const NOTICE_LEAD: usize = 6;
const NESTED_APP: &str = "zellij";
const COUNTS: [Count; 4] = [Count::Failed, Count::Working, Count::Idle, Count::Command];

// --- [MODELS] --------------------------------------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Role {
    Top,
    Bottom,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Class {
    Tally(Count),
    Ask(&'static str),
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct Row {
    id: u32,
    tab: usize,
    label: String,
    class: Class,
}

#[derive(Debug, Default, PartialEq, Eq)]
struct Census {
    rows: Vec<Row>,
    terminals: Vec<u32>,
    focused: Vec<u32>,
}

#[derive(Debug, Default)]
struct Client {
    mode: InputMode,
    session: String,
    tabs: Vec<TabInfo>,
    hover: Option<(Hit, Instant)>,
    cursors: BTreeMap<Hit, usize>,
    bound: bool,
}

#[derive(Default)]
struct State {
    slots: BTreeMap<SlotId, Role>,
    clients: BTreeMap<ClientId, Client>,
    census: Census,
    asks: Vec<u32>,
    focus: BTreeMap<ClientId, u32>,
    lit: BTreeSet<u32>,
    reconciled: bool,
    granted: bool,
    drawn: BTreeMap<(SlotId, ClientId), Line>,
}

// --- [OPERATIONS] ----------------------------------------------------------------------

const fn face(count: Count) -> (&'static str, &'static str, u32) {
    match count {
        Count::Failed => ("x", "failed", P.fail),
        Count::Working => ("●", "working", P.run),
        Count::Idle => ("○", "idle", P.idle),
        Count::Command => ("›", "command", P.subtle),
    }
}

fn classify(pane: &PaneInfo) -> Option<Class> {
    let attention = &pane.attention;
    let agent = pane.program_status.iter().find(|record| record.is_root()).is_some_and(|record| record.app.as_deref() != Some(NESTED_APP));
    match (attention.is_muted(), attention.status, attention.source) {
        (true, ..) => None,
        (_, AttentionStatus::NeedsYou, source) => Some(Class::Ask(match (source, attention.detail.kind) {
            (_, Some(BlockedKind::Question)) => "question",
            (_, Some(BlockedKind::Permission)) => "permission",
            (_, Some(BlockedKind::Auth)) => "login",
            (Some(AttentionSource::Bell), None) => "bell",
            (Some(AttentionSource::Notification), None) => "notice",
            (Some(AttentionSource::Watch), None) => "watch",
            _ => "input",
        })),
        (_, AttentionStatus::Failed, _) => Some(Class::Tally(Count::Failed)),
        (_, AttentionStatus::Working, Some(AttentionSource::ProgramStatus)) if agent => Some(Class::Tally(Count::Working)),
        (_, AttentionStatus::Working, Some(AttentionSource::ShellCommand | AttentionSource::ForegroundProcess | AttentionSource::CommandPane)) => {
            Some(Class::Tally(Count::Command))
        },
        (_, AttentionStatus::Idle, _) if agent => Some(Class::Tally(Count::Idle)),
        _ => None,
    }
}

fn shorten(text: &str, cols: usize) -> String {
    if text.width() <= cols {
        return text.to_owned();
    }
    let kept: String = text.chars().scan(0, |used, glyph| {
        *used += glyph.width().unwrap_or(0);
        (*used < cols).then_some(glyph)
    }).collect();
    format!("{kept}…")
}

fn label(pane: &PaneInfo) -> String {
    let state = &pane.command_state;
    let command = state.running.as_ref().and_then(|running| running.command.as_ref()).or_else(|| state.last.as_ref().and_then(|last| last.command.as_ref()));
    shorten(command.map_or(pane.title.as_str(), |command| command.text.as_str()), LABEL_COLS)
}

impl Census {
    fn from(manifest: &PaneManifest) -> Self {
        let terminals = manifest.panes.iter().flat_map(|(tab, panes)| panes.iter().filter(|pane| !pane.is_plugin).map(move |pane| (*tab, pane)));
        let mut rows: Vec<Row> = terminals
            .clone()
            .filter_map(|(tab, pane)| classify(pane).map(|class| Row { id: pane.id, tab, label: label(pane), class }))
            .collect();
        rows.sort_by_key(|row| (row.tab, row.id));
        Self { rows, focused: terminals.clone().filter(|(_, pane)| pane.is_focused).map(|(_, pane)| pane.id).collect(), terminals: terminals.map(|(_, pane)| pane.id).collect() }
    }

    fn of(&self, count: Count) -> impl Iterator<Item = &Row> {
        self.rows.iter().filter(move |row| row.class == Class::Tally(count))
    }
}

impl State {
    fn ask(&self, id: u32) -> Option<(&Row, &'static str)> {
        self.census.rows.iter().find(|row| row.id == id).and_then(|row| match row.class {
            Class::Ask(kind) => Some((row, kind)),
            Class::Tally(_) => None,
        })
    }

    fn timer(&mut self) -> RenderResponse {
        let now = Instant::now();
        let (expired, pending) = self.clients.values_mut().fold((false, None::<Duration>), |(expired, pending), client| match client.hover {
            Some((_, until)) if until <= now => {
                client.hover = None;
                (true, pending)
            },
            Some((_, until)) => (expired, Some(pending.map_or(until - now, |held| held.max(until - now)))),
            None => (expired, pending),
        });
        if let Some(wait) = pending {
            set_timeout(wait.as_secs_f64());
        }
        if expired { RenderResponse::All } else { RenderResponse::Nothing }
    }

    fn panes(&mut self, manifest: &PaneManifest) -> bool {
        let census = Census::from(manifest);
        if census == self.census && self.reconciled {
            return false;
        }
        self.census = census;
        let asking: Vec<u32> = self.census.rows.iter().filter(|row| matches!(row.class, Class::Ask(_))).map(|row| row.id).collect();
        self.asks.retain(|id| asking.contains(id));
        asking.into_iter().for_each(|id| {
            if !self.asks.contains(&id) {
                self.asks.push(id);
            }
        });
        self.light();
        true
    }

    fn light(&mut self) {
        let want: BTreeSet<u32> = self.asks.iter().copied().filter(|id| !self.focus.values().any(|focused| focused == id)).collect();
        let stale: Vec<u32> = if self.reconciled {
            self.lit.difference(&want).copied().collect()
        } else {
            self.census.terminals.iter().filter(|id| !want.contains(id)).copied().collect()
        };
        let fresh: Vec<u32> = want.difference(&self.lit).copied().collect();
        if !fresh.is_empty() || !stale.is_empty() {
            highlight_and_unhighlight_panes(fresh.into_iter().map(PaneId::Terminal).collect(), stale.into_iter().map(PaneId::Terminal).collect());
        }
        self.lit = want;
        self.reconciled = true;
    }

    fn bind(&self) {
        let pipe = Action::KeybindPipe {
            name: Some("next".to_owned()),
            payload: None,
            args: None,
            plugin: None,
            plugin_id: Some(get_plugin_ids().plugin_id),
            configuration: None,
            launch_new: false,
            skip_cache: false,
            floating: None,
            in_place: None,
            cwd: None,
            pane_title: None,
        };
        let (Ok(chord), Ok(key)) = (NEXT_CHORD.parse::<KeyWithModifier>(), NEXT_KEY.parse::<KeyWithModifier>()) else { return };
        let rebinds = NEXT_MODES
            .iter()
            .map(|mode| (*mode, chord.clone(), vec![pipe.clone()]))
            .chain([(InputMode::Session, key, vec![pipe.clone(), Action::SwitchToMode { input_mode: InputMode::Normal }])])
            .collect();
        rebind_keys(Vec::new(), rebinds, false);
    }

    fn hovering(client: &Client) -> Option<Hit> {
        client.hover.map(|(hit, _)| hit)
    }

    fn readout(&self, client: &Client, hit: Hit) -> Line {
        let mut line = Line::default();
        let at = |line: &mut Line, tab: usize| {
            line.push(bold(ink(P.fg)), format_args!(" tab {}", tab + 1));
        };
        match hit {
            Hit::Notice => self.asks.iter().filter_map(|id| self.ask(*id)).enumerate().for_each(|(index, (row, kind))| {
                line.gap(if index == 0 { 0 } else { 3 }).push(bold(ink(P.need)), kind).push(ink(P.subtle), " ·");
                at(&mut line, row.tab);
            }),
            Hit::Count(count) => {
                let (_, word, tone) = face(count);
                line.push(bold(ink(tone)), word);
                let rows: Vec<&Row> = self.census.of(count).collect();
                if rows.is_empty() {
                    line.push(ink(P.subtle), " · none");
                }
                rows.iter().for_each(|row| {
                    line.push(ink(P.subtle), " ·");
                    if matches!(count, Count::Failed | Count::Command) {
                        line.push(ink(P.subtle), format_args!(" {}", row.label));
                    }
                    at(&mut line, row.tab);
                });
            },
            Hit::Tab(position) => {
                line.push(bold(ink(P.fg)), format_args!("tab {}", position + 1));
                let name = client.tabs.get(position).map_or("", |tab| tab.name.as_str());
                if !name.is_empty() && name != format!("Tab #{}", position + 1) {
                    line.push(ink(P.subtle), format_args!(" · {}", shorten(name, LABEL_COLS)));
                }
                self.census.rows.iter().filter(|row| row.tab == position).for_each(|row| match row.class {
                    Class::Ask(kind) => {
                        line.push(ink(P.subtle), " · ").push(bold(ink(P.need)), kind);
                    },
                    Class::Tally(Count::Failed) => {
                        line.push(ink(P.subtle), " · ").push(bold(ink(P.fail)), "failed");
                    },
                    Class::Tally(_) => {},
                });
            },
            Hit::Session => {
                line.push(bold(ink(P.fg)), format_args!("session {}", client.session))
                    .push(ink(P.subtle), format_args!(" · {} tabs · {} panes", client.tabs.len(), self.census.terminals.len()));
            },
        }
        line
    }

    fn top(&self, client: &Client, cols: usize) -> Line {
        let hovered = |hit: Hit| Self::hovering(client) == Some(hit);
        let fill = on(ink(P.inverse), P.focus);
        let tabs = |fold: bool| {
            let mut line = Line::default();
            line.push(ink(P.focus), '▐').push(bold(fill), " TAB");
            let mut folded = false;
            client.tabs.iter().for_each(|tab| {
                let mark = match (tab.attention.counts.needs_you, tab.attention.counts.failed) {
                    (1.., _) => Some(('!', Effects::BLINK)),
                    (0, 1..) => Some(('x', Effects::new())),
                    (0, 0) => None,
                };
                if fold && !tab.active && mark.is_none() {
                    if !folded {
                        line.push(on(ink(P.selected), P.focus), " …");
                    }
                    folded = true;
                    return;
                }
                line.push(fill, ' ');
                line.hit(Hit::Tab(tab.position), |line| {
                    let look = |style: Style| underline_if(style, hovered(Hit::Tab(tab.position)));
                    let number = tab.position + 1;
                    match (tab.active, mark) {
                        (true, _) if client.mode == InputMode::RenameTab => {
                            let name = if tab.name.is_empty() { "_" } else { tab.name.as_str() };
                            line.push(look(bold(fill)), format_args!("[{number} ")).push(look(fill), name).push(look(bold(fill)), ']');
                        },
                        (true, _) => {
                            line.push(look(bold(fill)), format_args!("[{number}]"));
                        },
                        (false, Some((mark, effect))) => {
                            line.push(look(bold(fill)), format_args!(" {number}")).push(with(look(bold(fill)), effect), mark);
                        },
                        (false, None) => {
                            line.push(look(on(ink(P.selected), P.focus)), format_args!(" {number} "));
                        },
                    }
                });
            });
            line.push(fill, ' ').push(ink(P.focus), '▌');
            line
        };
        let notice = |word: bool| {
            let mut line = Line::default();
            if let Some((_, kind)) = self.asks.first().and_then(|id| self.ask(*id)) {
                line.hit(Hit::Notice, |line| {
                    let style = underline_if(bold(ink(P.need)), hovered(Hit::Notice));
                    line.push(with(style, Effects::BLINK), '!');
                    if word {
                        line.push(style, format_args!(" {kind}"));
                    }
                });
            }
            line
        };
        let counts = |short: bool| {
            let mut line = Line::default();
            COUNTS.into_iter().for_each(|count| {
                let (glyph, _, tone) = face(count);
                let n = self.census.of(count).count();
                if n == 0 {
                    return;
                }
                line.hit(Hit::Count(count), |line| {
                    let style = underline_if(ink(tone), hovered(Hit::Count(count)));
                    let style = if matches!(count, Count::Failed | Count::Command) { bold(style) } else { style };
                    line.push(style, glyph).push(ink(tone), format_args!(" {n}"));
                });
                line.gap(2);
            });
            if line.width() > 0 {
                line.gap(2);
            }
            let name = shorten(&client.session.to_uppercase(), if short { 3 } else { SESSION_COLS });
            line.push(ink(P.session), '▐').hit(Hit::Session, |line| {
                line.push(underline_if(bold(on(ink(P.inverse), P.session)), hovered(Hit::Session)), format_args!(" {name} "));
            });
            line.push(ink(P.session), '▌');
            line
        };
        let anchor = (cols / 2).saturating_sub(NOTICE_LEAD);
        (0..=3)
            .find_map(|level| compose(&tabs(level >= 3), &notice(level < 1), &counts(level >= 2), cols, anchor))
            .unwrap_or_else(|| {
                let mut line = tabs(true);
                line.gap(1).append(&notice(false)).gap(1).append(&counts(true));
                line
            })
            .clip(cols)
    }

    fn bottom(&self, client: &Client, cols: usize) -> Line {
        let current = ribbon(client.mode);
        let normal = client.mode == InputMode::Normal;
        let inner = cols.saturating_sub(2);
        let left = |labels: bool| {
            let mut line = Line::default();
            line.push(bold(on(ink(current.label), current.fill)), format_args!(" {} ", current.chip)).push(ink(current.fill), '▌').gap(2);
            if !current.note.is_empty() {
                line.push(ink(P.muted), current.note).gap(4);
            }
            current.groups.iter().enumerate().for_each(|(index, group)| {
                line.gap(if index == 0 { 0 } else { 4 });
                if let Some(layer) = group.layer {
                    line.push(bold(ink(layer.color)), layer.mark).gap(if group.joined { 0 } else { 2 });
                }
                group.hints.iter().enumerate().for_each(|(at, (key, word, keep))| {
                    line.gap(if at == 0 { 0 } else { 2 }).push(bold(ink(P.fg)), key);
                    if labels || *keep {
                        line.push(ink(P.muted), format_args!(" {word}"));
                    }
                });
            });
            line
        };
        let right = |left_width: usize, legend: bool, word: bool| {
            let mut line = Line::default();
            if current.done {
                line.push(bold(ink(P.fg)), '⏎').push(ink(P.muted), " done");
            }
            if normal && !self.asks.is_empty() {
                line.push(bold(ink(HYPER.color)), HYPER.mark).push(bold(ink(P.need)), format_args!(" {NEXT_KEY}"));
                if word {
                    line.push(ink(P.muted), " next");
                }
                line.gap(4);
            }
            match Self::hovering(client).filter(|_| normal && legend) {
                Some(hit) => {
                    let room = inner.saturating_sub(left_width + line.width() + 2);
                    line.append(&self.readout(client, hit).clip(room));
                },
                None if legend && (normal || client.mode == InputMode::Locked) => {
                    [&HYPER, &SUPER].into_iter().enumerate().for_each(|(index, layer)| {
                        line.push(ink(P.muted), if index == 0 { "" } else { " · " })
                            .push(bold(ink(layer.color)), layer.mark)
                            .push(ink(P.muted), format_args!(" {}", layer.name));
                    });
                },
                None => {},
            }
            line.gap(1);
            line
        };
        let band = (0..=3)
            .find_map(|level| {
                let left = left(level < 2);
                compose(&left, &Line::default(), &right(left.width(), level < 1, level < 3), inner, 0)
            })
            .or_else(|| compose(&left(false), &Line::default(), &Line::default(), inner, 0))
            .unwrap_or_else(|| left(false))
            .clip(inner)
            .ground(P.surface);
        let mut line = Line::default();
        line.push(ink(current.fill), '▐').append(&band).push(ink(P.surface), '▌');
        line
    }

    fn click(&mut self, client_id: ClientId, hit: Hit) {
        let targets: Vec<u32> = match hit {
            Hit::Notice => self.asks.clone(),
            Hit::Count(count) => self.census.of(count).map(|row| row.id).collect(),
            Hit::Tab(position) => {
                if let Ok(index) = u32::try_from(position + 1) {
                    switch_tab_to(index);
                }
                Vec::new()
            },
            Hit::Session => {
                run_action(Action::ToggleSessionCard, BTreeMap::new());
                Vec::new()
            },
        };
        let here = self.focus.get(&client_id);
        let away: Vec<u32> = targets.iter().copied().filter(|id| Some(id) != here).collect();
        let targets = if away.is_empty() { targets } else { away };
        if targets.is_empty() {
            return;
        }
        let cursor = self.clients.entry(client_id).or_default().cursors.entry(hit).or_default();
        let id = targets[*cursor % targets.len()];
        *cursor = cursor.wrapping_add(1);
        focus_terminal_pane(id, false, false);
    }

    fn mouse(&mut self, mouse: &Mouse, context: EventContext) -> bool {
        let (Some(slot), Some(client_id)) = (context.slot_id, context.client_id) else { return false };
        let at = |column: usize| self.drawn.get(&(slot, client_id)).and_then(|line| line.at(column));
        match mouse {
            Mouse::LeftClick(_, column) => {
                if let Some(hit) = at(*column) {
                    self.click(client_id, hit);
                }
                false
            },
            Mouse::Hover(_, column) => {
                let hover = at(*column).filter(|_| self.slots.get(&slot) == Some(&Role::Top));
                let client = self.clients.entry(client_id).or_default();
                let (changed, resting) = (Self::hovering(client) != hover, client.hover.is_none());
                client.hover = hover.map(|hit| (hit, Instant::now() + HOVER));
                if resting && hover.is_some() {
                    set_timeout(HOVER.as_secs_f64());
                }
                changed
            },
            _ => false,
        }
    }
}

// --- [COMPOSITION] ---------------------------------------------------------------------

register_shared_plugin!(State);

impl ZellijSharedPlugin for State {
    fn load(&mut self, _configuration: BTreeMap<String, String>) {
        request_permission(&[
            PermissionType::ReadApplicationState,
            PermissionType::ChangeApplicationState,
            PermissionType::RunActionsAsUser,
            PermissionType::ReadPaneContents,
            PermissionType::Reconfigure,
        ]);
        subscribe(&[
            EventType::ModeUpdate,
            EventType::TabUpdate,
            EventType::PaneUpdate,
            EventType::ListClients,
            EventType::Mouse,
            EventType::Timer,
            EventType::PermissionRequestResult,
        ]);
    }

    fn slot_added(&mut self, slot: Slot) {
        let role = match slot.configuration.get("role").map(String::as_str) {
            Some("bottom") => Role::Bottom,
            _ => Role::Top,
        };
        if slot.kind == SlotKind::Pane {
            set_selectable(false);
        }
        self.slots.insert(slot.id, role);
    }

    fn slot_removed(&mut self, slot_id: SlotId) {
        self.slots.remove(&slot_id);
        self.drawn.retain(|(slot, _), _| *slot != slot_id);
    }

    fn client_disconnected(&mut self, client_id: ClientId) {
        self.clients.remove(&client_id);
        self.drawn.retain(|(_, client), _| *client != client_id);
    }

    fn update(&mut self, event: Event, context: EventContext) -> RenderResponse {
        let targets: Vec<ClientId> = context.client_id.map_or_else(|| self.clients.keys().copied().collect(), |client_id| vec![client_id]);
        match event {
            Event::PermissionRequestResult(PermissionStatus::Granted) => {
                self.granted = true;
                self.bind();
                RenderResponse::Nothing
            },
            Event::Timer(_) => self.timer(),
            Event::ModeUpdate(info) => {
                let changed = targets.iter().fold(false, |changed, client_id| {
                    let client = self.clients.entry(*client_id).or_default();
                    let session = info.session_name.clone().unwrap_or_default();
                    let moved = client.mode != info.mode || client.session != session;
                    client.mode = info.mode;
                    client.session = session;
                    changed | moved
                });
                let unbound = context.client_id.and_then(|client_id| self.clients.get_mut(&client_id)).filter(|client| !client.bound);
                if let (true, Some(client)) = (self.granted, unbound) {
                    client.bound = true;
                    self.bind();
                }
                if changed { RenderResponse::All } else { RenderResponse::Nothing }
            },
            Event::TabUpdate(tabs) if tabs.iter().any(|tab| tab.active) => {
                let changed = targets.iter().fold(false, |changed, client_id| {
                    let client = self.clients.entry(*client_id).or_default();
                    let moved = client.tabs != tabs;
                    client.tabs = tabs.clone();
                    changed | moved
                });
                if changed {
                    list_clients();
                    RenderResponse::All
                } else {
                    RenderResponse::Nothing
                }
            },
            Event::PaneUpdate(manifest) => {
                if self.panes(&manifest) {
                    list_clients();
                    RenderResponse::All
                } else {
                    RenderResponse::Nothing
                }
            },
            Event::ListClients(clients) => {
                let focus: BTreeMap<ClientId, u32> = clients
                    .iter()
                    .filter_map(|client| match client.pane_id {
                        PaneId::Terminal(id) => Some((client.client_id, id)),
                        PaneId::Plugin(_) => None,
                    })
                    .collect();
                if focus != self.focus {
                    self.focus = focus;
                    self.light();
                }
                RenderResponse::Nothing
            },
            Event::Mouse(mouse) => {
                if self.mouse(&mouse, context) { RenderResponse::All } else { RenderResponse::Nothing }
            },
            _ => RenderResponse::Nothing,
        }
    }

    fn pipe(&mut self, message: PipeMessage, context: EventContext) -> RenderResponse {
        let only = (self.clients.len() == 1).then(|| self.clients.keys().next().copied()).flatten();
        if let (true, Some(client_id)) = (message.name == "next", context.client_id.or(only)) {
            self.click(client_id, Hit::Notice);
        }
        RenderResponse::Nothing
    }

    fn render(&mut self, _rows: usize, cols: usize, slot_id: SlotId, client_id: ClientId) {
        self.clients.entry(client_id).or_default();
        let Some(client) = self.clients.get(&client_id) else { return };
        let line = match self.slots.get(&slot_id) {
            Some(Role::Bottom) => self.bottom(client, cols),
            _ => self.top(client, cols),
        };
        print!("{}", line.ansi());
        self.drawn.insert((slot_id, client_id), line);
    }
}
