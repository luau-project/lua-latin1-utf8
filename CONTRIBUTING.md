## Contributing

### Submitting a pull request

1. Fork and clone the repository
2. Create a new branch for the changes: `git checkout -b my-branch`
3. Install test dependencies:
    * Install busted: `luarocks install busted`
    * Install luacov: `luarocks install luacov`
4. Make your changes
5. Build the project: `luarocks make "rockspecs/lua-latin1-utf8-dev-1.rockspec"`
6. Test your changes locally:
    * Run the test suite: `lua "test.lua"`
    * Run code coverage: `lua "-lluacov" "test.lua"`
7. Push the changes to your fork and submit a pull request
8. Wait for your pull request to be reviewed

### Resources

* [How to Contribute to Open Source](https://opensource.guide/how-to-contribute/)
* [Using Pull Requests](https://help.github.com/articles/about-pull-requests/)
* [GitHub Help](https://help.github.com)