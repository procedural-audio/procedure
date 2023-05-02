pub trait Loadable {
    fn load(path: &str) -> Result<Self, String> where Self: Sized;
}