type NodeId = u32;
type WidgetId = u32;

enum Event {
    AddNode(NodeId, String),
    RemoveNode(NodeId, String),
    AddCable(NodeId, NodeId),
    RemoveCable(NodeId, NodeId),
    UpdateWidget(NodeId, WidgetId, String),
    UpdateWidgetSilent(NodeId, WidgetId, String),
}

impl Event {
    fn apply(&self) {
        todo!()
    }

    fn undo(&self) {
        todo!()
    }
}

struct History {
    events: Vec<Event>,
}

impl History {
    fn new() -> Self {
        Self { events: Vec::new() }
    }

    fn apply(&mut self, event: Event) {
        self.events.push(event);
    }

    fn update(&mut self) {
        self.events.pop();
    }

    fn redo(&mut self) {
        todo!()
    }

    fn undo(&mut self) {
        todo!()
    }
}