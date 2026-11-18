_: {
  home.file = {
    "Library/Application Support/Unreal Engine/UnrealBuildTool/BuildConfiguration.xml".text = ''
      <?xml version="1.0" encoding="utf-8" ?>
      <Configuration xmlns="https://www.unrealengine.com/BuildConfiguration">
        <BuildConfiguration>
          <bAllowUBAExecutor>false</bAllowUBAExecutor>
        </BuildConfiguration>
      </Configuration>
    '';
    "Library/Application Support/Epic/Unreal Engine/Engine/Config/UserEngine.ini".text = ''
      [/Script/PythonScriptPlugin.PythonScriptPluginSettings]
      bRemoteExecution=True

      [Core.Log]
      LogPython=Verbose
      LogPythonRemoteExecution=Verbose
      LogModelContextProtocol=Verbose
      LogRemoteControl=Verbose
    '';
    "Library/Application Support/Epic/Unreal Engine/Engine/Config/UserEditorPerProjectUserSettings.ini".text = ''
      [/Script/PythonScriptPlugin.PythonScriptPluginUserSettings]
      bDeveloperMode=True
      TypeHintingMode=TypeChecker

      [/Script/ModelContextProtocolEngine.ModelContextProtocolSettings]
      bAutoStartServer=True
    '';
  };
}
