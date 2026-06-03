## Information

- `attic` must be manually configured after installation (to login to the `yaka-cache`)
- Using `attic watch-store` is preferred over a nix `post-build-hook` as the latter is synchronous and will therefore delay the build for nothing
