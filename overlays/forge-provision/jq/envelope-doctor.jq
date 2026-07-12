. + {
  ports: $ports,
  resources: (.resources + {
    runtime: {
      forgeProvision: {present: true, schemaVersion: $schemaVersion},
      docker: {
        present: ($dockerPath != "-"),
        executableKind: (if $dockerPath == "-" then null elif ($dockerPath | startswith("/nix/store/")) then "nix-store" else "host-path" end),
        policy: {status: $policyStatus, reason: (if $policyReason == "" then null else $policyReason end)},
        endpointKind: (if $resolvedEndpoint | startswith("unix://") then "unix" elif $resolvedEndpoint | startswith("tcp://") then "tcp" elif $resolvedEndpoint | startswith("ssh://") then "ssh" else "unknown" end),
        endpointPathExists: $endpointPathExists,
        state: $dockerState,
        compose: $composeVersion,
        server: $dockerServer,
        hostConfig: {
          credentialHelperPresent: ($hostCredsStore != "none" or $hostCredHelpers != "0"),
          credHelpers: (try ($hostCredHelpers | tonumber) catch null),
          warning: (if $hostCredsStore != "none" or $hostCredHelpers != "0" then "credential-helper-present-for-host-config" else null end)
        },
        anonymousPullConfig: {exists: $anonymousConfigExists}
      },
      compose: {present: ($composeVersion != "unavailable"), version: (if $composeVersion == "unavailable" then null else $composeVersion end)},
      jq: {present: true},
      listenerProbeMethod: $listenerProbeMethod,
      portsInspectable: $portsInspectable,
      portsUsable: ($portsInspectable and all($ports[]; .state == "disabled" or .owner == "none" or .owner == "provision:this-project")),
      blockedPorts: [$ports[] | select(.state != "disabled" and .owner != "none" and .owner != "provision:this-project")],
      lock: $lock,
      colima: $colima,
      appleContainer: $appleContainer,
      anonymousDockerConfig: $anonymousConfigExists,
      hostCredentialHelperPresent: ($hostCredsStore != "none" or $hostCredHelpers != "0")
    }
  })
}
+ if $diagnostic then {diagnostic: {endpointFingerprint: (if $endpointFingerprint == "" then null else $endpointFingerprint end), dockerEndpointRedacted: true, dockerPathRedacted: true}} else {} end
