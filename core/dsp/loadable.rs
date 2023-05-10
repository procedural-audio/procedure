use std::sync::{Arc, RwLock, RwLockReadGuard, RwLockWriteGuard, TryLockError};

pub trait Loadable {
    fn load(path: &str) -> Result<Self, String> where Self: Sized;
}

pub struct Lock<T> {
    inner: Arc<RwLock<T>>
}

impl<T> Lock<T> {
    pub fn new(inner: T) -> Self {
        Self {
            inner: Arc::new(RwLock::new(inner))
        }
    }

    pub fn read(&self) -> RwLockReadGuard<'_, T> {
        self.inner.read().unwrap()
    }

    pub fn write(&self) -> RwLockWriteGuard<'_, T> {
        self.inner.write().unwrap()
    }

    pub fn try_read(&self) -> Result<RwLockReadGuard<'_, T>, TryLockError<RwLockReadGuard<'_, T>>> {
        self.inner.try_read()
    }

    pub fn try_write(&self) -> Result<RwLockWriteGuard<'_, T>, TryLockError<RwLockWriteGuard<'_, T>>> {
        self.inner.try_write()
    }

    pub fn realtime_read<F: FnMut(&T)>(&self, mut f: F) {
        if let Ok(lock) = self.inner.try_read() {
            f(&*lock);
        }
    }
}

impl<T> Clone for Lock<T> {
    fn clone(&self) -> Self {
        Self { inner: self.inner.clone() }
    }
}
