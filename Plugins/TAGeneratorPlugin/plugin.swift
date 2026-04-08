import PackagePlugin

@main
struct TAGeneratorPlugin: BuildToolPlugin {
  func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
    let generator = try context.tool(named: "TACodeGenerator")

    let xmlFile = context.package.directoryURL
      .appending(path: "Sources/ta-lib/ta_func_api.xml")

    let outputDir = context.pluginWorkDirectoryURL
    let outputFile = outputDir.appending(path: "ta_func_api.swift")

    return [
      .buildCommand(
        displayName: "Generate TA-Lib Swift wrappers",
        executable: generator.url,
        arguments: [xmlFile.path(percentEncoded: false), outputFile.path(percentEncoded: false)],
        inputFiles: [xmlFile],
        outputFiles: [outputFile]
      )
    ]
  }
}
