mod bar;

use std::collections::BTreeMap;

use zellij_tile::prelude::{actions::Action, *};

use crate::bar::{Bar, Click, Line, View};

// --- [MODELS] --------------------------------------------------------------------------

#[derive(Default)]
struct State {
    bar: Bar,
    mode: InputMode,
    session: Option<String>,
    tabs: Vec<TabInfo>,
    attention: AttentionCounts,
    parts: [Line; 3],
    cols: usize,
}

// --- [OPERATIONS] ----------------------------------------------------------------------

impl State {
    fn redraw(&mut self) -> bool {
        let view = View { mode: self.mode, session: self.session.as_deref(), tabs: &self.tabs, attention: &self.attention };
        let parts = bar::parts(&self.bar, view);
        let changed = parts != self.parts;
        self.parts = parts;
        changed
    }

    fn click(&self, column: usize) {
        match bar::layout(&self.bar, &self.parts, self.cols).hit(column) {
            Some(Click::Tab(position)) => {
                if let Ok(index) = u32::try_from(position + 1) {
                    switch_tab_to(index);
                }
            },
            Some(Click::SwapLayout) => next_swap_layout(),
            Some(Click::Attention) => run_action(Action::ToggleSessionCard, BTreeMap::new()),
            None => {},
        }
    }
}

// --- [COMPOSITION] ---------------------------------------------------------------------

register_plugin!(State);

impl ZellijPlugin for State {
    fn load(&mut self, configuration: BTreeMap<String, String>) {
        self.bar = Bar::new(&configuration);
        set_selectable(false);
        request_permission(&[
            PermissionType::ReadApplicationState,
            PermissionType::ChangeApplicationState,
            PermissionType::RunActionsAsUser,
        ]);
        subscribe(&[
            EventType::ModeUpdate,
            EventType::TabUpdate,
            EventType::GlobalAttentionUpdate,
            EventType::InitialKeybinds,
            EventType::Mouse,
        ]);
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::ModeUpdate(info) => {
                self.mode = info.mode;
                self.session = info.session_name;
                self.redraw()
            },
            Event::TabUpdate(tabs) => {
                self.tabs = tabs;
                self.redraw()
            },
            Event::GlobalAttentionUpdate(global) => {
                self.attention = global.counts;
                self.redraw()
            },
            Event::Mouse(Mouse::LeftClick(_, column)) => {
                self.click(column);
                false
            },
            _ => false,
        }
    }

    fn render(&mut self, _rows: usize, cols: usize) {
        self.cols = cols;
        print!("{}", bar::layout(&self.bar, &self.parts, cols).ansi());
    }
}
