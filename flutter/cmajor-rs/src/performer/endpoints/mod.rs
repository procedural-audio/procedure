pub mod event;
pub mod stream;
pub mod value;

/// An endpoint.
#[derive(Debug, Copy, Clone, PartialEq)]
pub struct Endpoint<T>(pub T);
