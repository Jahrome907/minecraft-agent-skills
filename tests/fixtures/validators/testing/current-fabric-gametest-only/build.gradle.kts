// Static validator fixture: the real project supplies Loom and Fabric API.
// This fragment exercises GameTest source-set discovery, not Gradle compilation.

fabricApi {
    configureTests {
        createSourceSet = true
        enableGameTests = true
    }
}
