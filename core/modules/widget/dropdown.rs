use crate::widget::*;

#[repr(C)]
pub struct Dropdown<'a> {
    pub index: &'a mut usize,
    pub color: Color,
    pub elements: &'static [&'static str],
}

impl<'a> WidgetNew for Dropdown<'a> {
    fn get_name(&self) -> &'static str {
        "Dropdown"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_dropdown_set_index(dropdown: &mut Dropdown, index: usize) {
    *dropdown.index = index;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_dropdown_get_index(dropdown: &mut Dropdown) -> usize {
    *dropdown.index
}

#[no_mangle]
pub unsafe extern "C" fn ffi_dropdown_get_element_count(dropdown: &mut Dropdown) -> usize {
    dropdown.elements.len()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_dropdown_get_color(dropdown: &mut Dropdown) -> u32 {
    dropdown.color.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_dropdown_get_element(
    dropdown: &mut Dropdown,
    index: usize,
) -> *const i8 {
    let s = CString::new(dropdown.elements[index]).unwrap();
    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

/* ========== Dropdown Icons ========== */

#[repr(C)]
pub struct DropdownIcons<'a> {
    pub elements: &'static [(&'static str, &'static str)],
    pub color: Color,
    pub on_changed: Box<dyn FnMut(usize) + 'a>,
}

impl<'a> WidgetNew for DropdownIcons<'a> {
    fn get_name(&self) -> &'static str {
        "DropdownIcon"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_dropdown_icon_on_changed(dropdown: &mut DropdownIcons, index: usize) {
    (dropdown.on_changed)(index);
    // CHECK IF SHOULD REFRESH
}

#[no_mangle]
pub unsafe extern "C" fn ffi_dropdown_icon_get_element_count(
    dropdown: &mut DropdownIcons,
) -> usize {
    dropdown.elements.len()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_dropdown_icon_get_color(dropdown: &mut DropdownIcons) -> u32 {
    dropdown.color.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_dropdown_icon_get_element(
    dropdown: &mut DropdownIcons,
    index: usize,
) -> *const i8 {
    let s = CString::new(dropdown.elements[index].0).unwrap();
    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

#[no_mangle]
pub unsafe extern "C" fn ffi_dropdown_icon_get_icon(
    dropdown: &mut DropdownIcons,
    index: usize,
) -> *const i8 {
    let s = CString::new(dropdown.elements[index].1).unwrap();
    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

/* ========== Canvas ========== */

pub struct Path {}

#[derive(Copy, Clone)]
#[repr(C)]
pub struct Paint {
    pub color: Color,
    pub width: f32,
}

impl Paint {
    pub fn new() -> Self {
        return Self {
            color: Color::GREY,
            width: 2.0,
        };
    }

    pub fn set_color(&mut self, color: Color) {
        self.color = color;
    }

    pub fn set_width(&mut self, width: f32) {
        self.width = width;
    }
}

#[repr(u32)]
pub enum PaintActionKind {
    Circle = 0,
    Rect = 1,
    RRect = 2,
    Fill = 3,
    Line = 4,
    Points = 5,
    Path = 6,
    Polygon = 7,
}

#[repr(C)]
pub struct PaintAction {
    action: PaintActionKind,
    f1: f32,
    f2: f32,
    f3: f32,
    f4: f32,
    f5: f32,
    p1: *mut std::ffi::c_void,
    paint: Paint,
    points: Vec<(f32, f32)>
}

pub struct Canvas {
    actions: Vec<PaintAction>,
    pub width: f32,
    pub height: f32,
}

impl Canvas {
    pub fn clear(&mut self) {
        self.actions.clear();
    }

    pub fn draw_circle(&mut self, offset: (f32, f32), radius: f32, paint: Paint) {
        self.actions.push(PaintAction {
            action: PaintActionKind::Circle,
            f1: offset.0,
            f2: offset.1,
            f3: radius,
            f4: 0.0,
            f5: 0.0,
            p1: std::ptr::null_mut(),
            paint,
            points: Vec::new(),
        });
    }

    pub fn draw_rect(&mut self, offset: (f32, f32), size: (f32, f32), paint: Paint) {
        self.actions.push(PaintAction {
            action: PaintActionKind::Rect,
            f1: offset.0,
            f2: offset.1,
            f3: size.0,
            f4: size.1,
            f5: 0.0,
            p1: std::ptr::null_mut(),
            paint,
            points: Vec::new(),
        });
    }

    pub fn draw_rrect(&mut self, offset: (f32, f32), size: (f32, f32), radius: f32, paint: Paint) {
        self.actions.push(PaintAction {
            action: PaintActionKind::RRect,
            f1: offset.0,
            f2: offset.1,
            f3: size.0,
            f4: size.1,
            f5: radius,
            p1: std::ptr::null_mut(),
            paint,
            points: Vec::new(),
        });
    }

    pub fn fill(&mut self, color: Color) {
        let mut paint = Paint::new();
        paint.set_color(color);

        self.actions.push(PaintAction {
            action: PaintActionKind::Fill,
            f1: 0.0,
            f2: 0.0,
            f3: 0.0,
            f4: 0.0,
            f5: 0.0,
            p1: std::ptr::null_mut(),
            paint,
            points: Vec::new(),
        });
    }

    pub fn draw_line(&mut self, p1: (f32, f32), p2: (f32, f32), paint: Paint) {
        self.actions.push(PaintAction {
            action: PaintActionKind::Line,
            f1: p1.0,
            f2: p1.1,
            f3: p2.0,
            f4: p2.1,
            f5: 0.0,
            p1: std::ptr::null_mut(),
            paint,
            points: Vec::new(),
        });
    }

    pub fn draw_points(&mut self, points: Vec<(f32, f32)>, paint: Paint) {
        self.actions.push(PaintAction {
            action: PaintActionKind::Points,
            f1: 0.0,
            f2: 0.0,
            f3: 0.0,
            f4: 0.0,
            f5: 0.0,
            p1: std::ptr::null_mut(),
            paint,
            points,
        });
    }

    pub fn draw_path(&mut self, points: Vec<(f32, f32)>, paint: Paint) {
        self.actions.push(PaintAction {
            action: PaintActionKind::Path,
            f1: 0.0,
            f2: 0.0,
            f3: 0.0,
            f4: 0.0,
            f5: 0.0,
            p1: std::ptr::null_mut(),
            paint,
            points,
        });
    }

    pub fn draw_polygon(&mut self, points: Vec<(f32, f32)>, paint: Paint) {
        self.actions.push(PaintAction {
            action: PaintActionKind::Polygon,
            f1: 0.0,
            f2: 0.0,
            f3: 0.0,
            f4: 0.0,
            f5: 0.0,
            p1: std::ptr::null_mut(),
            paint,
            points,
        });
    }
}

pub struct Painter<F: Fn(&mut Canvas), G: Fn() -> bool> {
    pub paint: F,
    pub repaint: G
}

impl<F: Fn(&mut Canvas), G: Fn() -> bool> WidgetNew for Painter<F, G> {
    fn get_name(&self) -> &'static str {
        "Painter"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }

    fn get_trait<'w>(&'w self) -> &'w dyn WidgetNew {
        unsafe { std::mem::transmute(self as &dyn PainterTrait) }
    }
}

pub trait PainterTrait {
    fn paint(&self, canvas: &mut Canvas);
    fn repaint(&self) -> bool;
}

impl<F: Fn(&mut Canvas), G: Fn() -> bool> PainterTrait for Painter<F, G> {
    fn paint(&self, canvas: &mut Canvas) {
        (self.paint)(canvas);
    }

    fn repaint(&self) -> bool {
        (self.repaint)()
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_painter_paint(painter: &mut dyn PainterTrait, canvas: &mut Canvas) {
    canvas.clear();
    painter.paint(canvas);
}

#[no_mangle]
pub unsafe extern "C" fn ffi_painter_repaint(painter: &mut dyn PainterTrait) -> bool {
    painter.repaint()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_new_canvas() -> *mut Canvas {
    return Box::into_raw(Box::new(Canvas {
        actions: Vec::new(),
        width: 0.0,
        height: 0.0
    }));
}

#[no_mangle]
pub unsafe extern "C" fn ffi_canvas_delete(canvas: *mut Canvas) {
    let _ = Box::from_raw(canvas);
}

#[no_mangle]
pub unsafe extern "C" fn ffi_canvas_get_actions(canvas: &mut Canvas) -> *mut PaintAction {
    canvas.actions.as_ptr() as *mut PaintAction
}

#[no_mangle]
pub unsafe extern "C" fn ffi_canvas_get_actions_count(canvas: &mut Canvas) -> usize {
    canvas.actions.len()
}

pub struct Painter2<F: Fn(f32) -> f32> {
    pub width: u32,
    pub color: Color,
    pub paint: F
}

impl<F: Fn(f32) -> f32> WidgetNew for Painter2<F> {
    fn get_name(&self) -> &'static str {
        "Painter2"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }

    fn get_trait<'w>(&'w self) -> &'w dyn WidgetNew {
        unsafe { std::mem::transmute(self as &dyn Painter2Trait) }
    }
}

pub trait Painter2Trait {
    fn get_stroke_width(&self) -> u32;
    fn get_color(&self) -> Color;
    fn paint(&self, x: f32) -> f32;
}

impl<F: Fn(f32) -> f32> Painter2Trait for Painter2<F> {
    fn get_stroke_width(&self) -> u32 {
        self.width
    }

    fn get_color(&self) -> Color {
        self.color
    }

    fn paint(&self, x: f32) -> f32 {
        (self.paint)(x)
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_painter2_get_stroke_width(painter: &dyn Painter2Trait) -> u32 {
    painter.get_stroke_width()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_painter2_get_color(painter: &dyn Painter2Trait) -> u32 {
    painter.get_color().0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_painter2_paint(painter: &dyn Painter2Trait, x: f32) -> f32{
    painter.paint(x)
}

pub struct Plotter<'w> {
    pub value: &'w f32,
    pub thickness: f32,
    pub color: Color,
}

impl<'a> WidgetNew for Plotter<'a> {
    fn get_name(&self) -> &'static str {
        "Plotter"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_plotter_get_value(plotter: &Plotter) -> f32 {
    *plotter.value
}

#[no_mangle]
pub unsafe extern "C" fn ffi_plotter_get_color(plotter: &Plotter) -> Color {
    plotter.color
}

#[no_mangle]
pub unsafe extern "C" fn ffi_plotter_get_thickness(plotter: &Plotter) -> f32 {
    plotter.thickness
}

pub enum MouseEvent {
    Down(f32, f32),
    Up(f32, f32),
    Drag(f32, f32)
}

pub struct MouseListener<F: FnMut(MouseEvent), T: WidgetNew> {
    pub on_event: F,
    pub child: T
}

impl<F: FnMut(MouseEvent), T: WidgetNew> WidgetNew for MouseListener<F, T> {
    fn get_name(&self) -> &'static str {
        "MouseListener"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &(self.child)
    }

    fn get_trait<'w>(&'w self) -> &'w dyn WidgetNew {
        unsafe { std::mem::transmute(self as &dyn MouseListenerTrait) }
    }
}

pub trait MouseListenerTrait {
    fn on_event(&mut self, event: MouseEvent);
}

impl<F: FnMut(MouseEvent), T: WidgetNew> MouseListenerTrait for MouseListener<F, T> {
    fn on_event(&mut self, event: MouseEvent) {
        (self.on_event)(event);
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_mouse_listener_on_down(widget: &mut dyn MouseListenerTrait, x: f32, y: f32) {
    widget.on_event(MouseEvent::Down(x, y));
}

#[no_mangle]
pub unsafe extern "C" fn ffi_mouse_listener_on_up(widget: &mut dyn MouseListenerTrait, x: f32, y: f32) {
    widget.on_event(MouseEvent::Up(x, y));
}

#[no_mangle]
pub unsafe extern "C" fn ffi_mouse_listener_on_drag(widget: &mut dyn MouseListenerTrait, x: f32, y: f32) {
    widget.on_event(MouseEvent::Drag(x, y));
}

/* ========== Tabs ========== */

pub trait TabsTuple {
    fn len(&self) -> usize;
    fn get(&self, index: usize) -> Option<&dyn WidgetNew>;
    fn get_icon(&self, index: usize) -> Option<Icon>;
}

impl<A: WidgetNew> TabsTuple for Tab<A> {
    fn len(&self) -> usize {
        1
    }

    fn get(&self, index: usize) -> Option<&dyn WidgetNew> {
        match index {
            0 => Some(&self.child),
            _ => None,
        }
    }

    fn get_icon(&self, index: usize) -> Option<Icon> {
        match index {
            0 => Some(self.icon),
            _ => None,
        }
    }
}

impl<A: WidgetNew, B: WidgetNew> TabsTuple for (Tab<A>, Tab<B>) {
    fn len(&self) -> usize {
        2
    }

    fn get(&self, index: usize) -> Option<&dyn WidgetNew> {
        match index {
            0 => Some(&self.0.child),
            1 => Some(&self.1.child),
            _ => None,
        }
    }

    fn get_icon(&self, index: usize) -> Option<Icon> {
        match index {
            0 => Some(self.0.icon),
            1 => Some(self.1.icon),
            _ => None,
        }
    }
}

impl<A: WidgetNew, B: WidgetNew, C: WidgetNew> TabsTuple for (Tab<A>, Tab<B>, Tab<C>) {
    fn len(&self) -> usize {
        3
    }

    fn get(&self, index: usize) -> Option<&dyn WidgetNew> {
        match index {
            0 => Some(&self.0.child),
            1 => Some(&self.1.child),
            2 => Some(&self.2.child),
            _ => None,
        }
    }

    fn get_icon(&self, index: usize) -> Option<Icon> {
        match index {
            0 => Some(self.0.icon),
            1 => Some(self.1.icon),
            2 => Some(self.2.icon),
            _ => None,
        }
    }
}

impl<A: WidgetNew, B: WidgetNew, C: WidgetNew, D: WidgetNew> TabsTuple
    for (Tab<A>, Tab<B>, Tab<C>, Tab<D>)
{
    fn len(&self) -> usize {
        4
    }

    fn get(&self, index: usize) -> Option<&dyn WidgetNew> {
        match index {
            0 => Some(&self.0.child),
            1 => Some(&self.1.child),
            2 => Some(&self.2.child),
            3 => Some(&self.3.child),
            _ => None,
        }
    }

    fn get_icon(&self, index: usize) -> Option<Icon> {
        match index {
            0 => Some(self.0.icon),
            1 => Some(self.1.icon),
            2 => Some(self.2.icon),
            3 => Some(self.3.icon),
            _ => None,
        }
    }
}

#[repr(C)]
pub struct Tabs<T: TabsTuple> {
    pub tabs: T
}

pub trait TabsTrait {
    fn get_tab_count(&self) -> usize;
    fn get_child(&self, index: usize) -> &dyn WidgetNew;
    fn get_icon(&self, index: usize) -> Icon;
}

impl<T: TabsTuple> TabsTrait for Tabs<T> {
    fn get_tab_count(&self) -> usize {
        self.tabs.len()
    }

    fn get_child(&self, index: usize) -> &dyn WidgetNew {
        self.tabs.get(index).unwrap()
    }

    fn get_icon(&self, index: usize) -> Icon {
        self.tabs.get_icon(index).unwrap()
    }

}

impl<T: TabsTuple> WidgetNew for Tabs<T> {
    fn get_name(&self) -> &'static str {
        "Tabs"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }

    fn get_trait<'w>(&'w self) -> &'w dyn WidgetNew {
        unsafe { std::mem::transmute(self as &dyn TabsTrait) }
    }
}

#[repr(C)]
pub struct Tab<T: WidgetNew> {
    pub child: T,
    pub icon: Icon,
}

#[no_mangle]
pub unsafe extern "C" fn ffi_tabs_get_tab_child(tabs: &dyn TabsTrait, index: usize) -> &dyn WidgetNew {
    tabs.get_child(index)
}

/*#[no_mangle]
pub unsafe extern "C" fn ffi_tabs_get_tab_icon(tabs: &dyn TabsTrait, index: usize) -> Icon {
    tabs.get_icon(index)
}*/

#[no_mangle]
pub unsafe extern "C" fn ffi_tabs_get_tab_count(tabs: &dyn TabsTrait) -> usize {
    tabs.get_tab_count()
}

/* ========== Icon ========== */

#[derive(Copy, Clone)]
#[repr(C)]
pub struct Icon {
    pub path: &'static str,
    pub color: Color,
}

impl Icon {
    // pub const Piano: Icon = Icon { path, color: Color::BLUE };
}

#[derive(Copy, Clone)]
#[repr(usize)]
pub enum IconData {
    File(&'static str),
    Piano,
    Sample,
    Code,
    Settings,
}

/* ========== DropdownBuilder ========== */

pub struct DropdownBuilder<'a, V, F, R: WidgetNew>
where
    F: FnOnce(usize, &'a mut V) -> R + 'a,
{
    pub columns: usize,
    pub state: &'a mut [V],
    pub builder: F,
}

impl<'a, V, F, R: WidgetNew> WidgetNew for DropdownBuilder<'a, V, F, R>
where
    F: FnOnce(usize, &'a mut V) -> R,
{
    fn get_name(&self) -> &'static str {
        "DropdownBuilder"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }

    fn get_trait<'w>(&'w self) -> &'w dyn WidgetNew {
        unsafe { std::mem::transmute(self as &dyn DropdownBuilderTrait) }
    }
}

pub trait DropdownBuilderTrait {
    fn get_count(&self) -> usize;
    fn get_columns(&self) -> usize;
    fn create_child(&mut self, index: usize) -> Box<dyn WidgetNew>;
}

impl<'a, V, F, R: WidgetNew> DropdownBuilderTrait for DropdownBuilder<'a, V, F, R>
where
    F: FnOnce(usize, &'a mut V) -> R,
{
    fn get_count(&self) -> usize {
        self.state.len()
    }

    fn get_columns(&self) -> usize {
        self.columns
    }

    fn create_child(&mut self, index: usize) -> Box<dyn WidgetNew> {
        // BREAKING RUST OWNERSHIP RULES HERE
        unsafe {
            let temp0: Self = std::mem::transmute_copy(self);
            let temp1: Box<dyn WidgetNew> = Box::new((temp0.builder)(
                index,
                std::mem::transmute(&mut self.state[index]),
            ));
            let temp2: Box<dyn WidgetNew> = std::mem::transmute_copy(&temp1);
            std::mem::forget(temp1);

            return temp2;
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_dropdown_builder_trait_get_count(
    dropdown_builder: &mut dyn DropdownBuilderTrait,
) -> usize {
    dropdown_builder.get_count()
}
