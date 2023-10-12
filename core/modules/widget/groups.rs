use crate::widget::*;
pub struct Stack<G: WidgetGroup> {
    pub children: G,
}

impl<G: WidgetGroup> WidgetNew for Stack<G> {
    fn get_name(&self) -> &'static str {
        "Stack"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &self.children
    }
}

pub struct Expanded<W: WidgetNew> {
    pub child: W
}

impl<W: WidgetNew> WidgetNew for Expanded<W> {
    fn get_name(&self) -> &'static str {
        "Expanded"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &(self.child)
    }
}

#[repr(C)]
pub struct Grid<G: WidgetGroup> {
    pub columns: usize,
    pub children: G,
}

impl<G: WidgetGroup> WidgetNew for Grid<G> {
    fn get_name(&self) -> &'static str {
        "Grid"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &self.children
    }
}

#[repr(C)]
pub struct GridFFI {
    pub columns: usize,
}

#[no_mangle]
pub unsafe extern "C" fn ffi_grid_get_columns(widget: &GridFFI) -> usize {
    widget.columns
}

pub struct Column<G: WidgetGroup> {
    pub children: G,
}

impl<G: WidgetGroup> WidgetNew for Column<G> {
    fn get_name(&self) -> &'static str {
        "Column"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &self.children
    }
}

pub struct Row<G: WidgetGroup> {
    pub children: G,
}

impl<G: WidgetGroup> WidgetNew for Row<G> {
    fn get_name(&self) -> &'static str {
        "Row"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &self.children
    }
}
