use std::path::Path;

/*use git2::{build::{CheckoutBuilder, RepoBuilder}, *};

/// Clone a public (HTTPS) repository into `destination`. If `version` is Some(...),
/// attempt to check out that branch/tag/commit.
pub fn clone_repository(url: &str, version: Option<&str>, destination: &str) -> Result<(), Error> {
    // Set up callbacks. For a public HTTPS repo, we often don't need special credentials.
    // You can expand this if your remote requires specific credentials or handling.
    let mut callbacks = RemoteCallbacks::new();

    // Fetch options let us attach the callbacks.
    let mut fetch_opts = FetchOptions::new();
    fetch_opts.remote_callbacks(callbacks);

    // Build the repo with the above fetch options.
    let mut builder = RepoBuilder::new();
    builder.fetch_options(fetch_opts);

    let destination = Path::new(destination);
    // Clone into the destination directory.
    let repo = builder.clone(url, destination)?;

    // If a version (branch, tag, or commit) was given, try to check it out.
    if let Some(version_str) = version {
        // You could try to fetch the branch name if it's not already fetched:
        // (Uncomment the following if you need to explicitly fetch a remote branch)
        //
        // let mut remote = repo.find_remote("origin")?;
        // remote.fetch(&[version_str], None, None)?;

        // This attempts to parse the reference (branch, tag, or even commit SHA).
        // For example, "refs/remotes/origin/my-branch", "refs/tags/some-tag", or
        // simply "master", "v1.0", or a SHA like "abc123".
        let (object, reference) = repo.revparse_ext(version_str)?;

        // Check out the tree associated with this reference.
        repo.checkout_tree(&object, Some(&mut CheckoutBuilder::new()))?;

        // Point HEAD to this reference (detached if we don't have a named reference).
        if let Some(gref) = reference {
            repo.set_head(gref.name().unwrap())?;
        } else {
            // If there is no direct reference (e.g. a commit SHA), detach HEAD.
            repo.set_head_detached(object.id())?;
        }
    }

    Ok(())
}
*/