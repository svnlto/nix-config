_:

{
  # Cross-platform k9s config
  # macOS: ~/Library/Application Support/k9s/
  # Linux: ~/.config/k9s/

  xdg.configFile = {
    "k9s/config.yaml".text = ''
      k9s:
        liveViewAutoRefresh: true
        gpuVendors: {}
        screenDumpDir: /tmp/k9s-screen-dumps
        refreshRate: 2
        apiServerTimeout: 15s
        maxConnRetry: 5
        readOnly: false
        noExitOnCtrlC: false
        portForwardAddress: localhost
        ui:
          enableMouse: false
          headless: true
          logoless: true
          crumbsless: false
          splashless: true
          reactive: false
          noIcons: false
          defaultsToFullScreen: false
          useFullGVRTitle: false
          skin: catppuccin-mocha
        skipLatestRevCheck: true
        disablePodCounting: false
        shellPod:
          image: busybox:1.35.0
          namespace: default
          limits:
            cpu: 100m
            memory: 100Mi
        imageScans:
          enable: false
          exclusions:
            namespaces: []
            labels: {}
        logger:
          tail: 500
          buffer: 5000
          sinceSeconds: -1
          textWrap: false
          disableAutoscroll: false
          showTime: true
        thresholds:
          cpu:
            critical: 90
            warn: 70
          memory:
            critical: 90
            warn: 70
        defaultView: pod
    '';

    "k9s/aliases.yaml".text = ''
      aliases:
        dp: deployments
        sec: v1/secrets
        jo: jobs
        cr: clusterroles
        crb: clusterrolebindings
        ro: roles
        rb: rolebindings
        np: networkpolicies
        pv: persistentvolumes
        pvc: persistentvolumeclaims
        ev: events
        no: nodes
        sts: statefulsets
        ds: daemonsets
        cm: configmaps
        ing: ingresses
        hr: helmreleases
    '';

    "k9s/skins/catppuccin-mocha.yaml".text = ''
      k9s:
        body:
          fgColor: '#cdd6f4'
          bgColor: '#1e1e2e'
          logoColor: '#cba6f7'
        prompt:
          fgColor: '#cdd6f4'
          bgColor: '#181825'
          suggestColor: '#89b4fa'
        help:
          fgColor: '#cdd6f4'
          bgColor: '#1e1e2e'
          sectionColor: '#a6e3a1'
          keyColor: '#89b4fa'
          numKeyColor: '#eba0ac'
        frame:
          title:
            fgColor: '#94e2d5'
            bgColor: '#1e1e2e'
            highlightColor: '#f5c2e7'
            counterColor: '#f9e2af'
            filterColor: '#a6e3a1'
          border:
            fgColor: '#cba6f7'
            focusColor: '#b4befe'
          menu:
            fgColor: '#cdd6f4'
            keyColor: '#89b4fa'
            numKeyColor: '#eba0ac'
          crumbs:
            fgColor: '#1e1e2e'
            bgColor: '#eba0ac'
            activeColor: '#f2cdcd'
          status:
            newColor: '#89b4fa'
            modifyColor: '#b4befe'
            addColor: '#a6e3a1'
            pendingColor: '#fab387'
            errorColor: '#f38ba8'
            highlightColor: '#89dceb'
            killColor: '#cba6f7'
            completedColor: '#6c7086'
        info:
          fgColor: '#fab387'
          sectionColor: '#cdd6f4'
        views:
          table:
            fgColor: '#cdd6f4'
            bgColor: '#1e1e2e'
            cursorFgColor: '#313244'
            cursorBgColor: '#45475a'
            markColor: '#f5e0dc'
            header:
              fgColor: '#f9e2af'
              bgColor: '#1e1e2e'
              sorterColor: '#89dceb'
          xray:
            fgColor: '#cdd6f4'
            bgColor: '#1e1e2e'
            cursorColor: '#45475a'
            cursorTextColor: '#1e1e2e'
            graphicColor: '#f5c2e7'
          charts:
            bgColor: '#1e1e2e'
            chartBgColor: '#1e1e2e'
            dialBgColor: '#1e1e2e'
            defaultDialColors:
              - '#a6e3a1'
              - '#f38ba8'
            defaultChartColors:
              - '#a6e3a1'
              - '#f38ba8'
            resourceColors:
              cpu:
                - '#cba6f7'
                - '#89b4fa'
              mem:
                - '#f9e2af'
                - '#fab387'
          yaml:
            keyColor: '#89b4fa'
            valueColor: '#cdd6f4'
            colonColor: '#a6adc8'
          logs:
            fgColor: '#cdd6f4'
            bgColor: '#1e1e2e'
            indicator:
              fgColor: '#b4befe'
              bgColor: '#1e1e2e'
              toggleOnColor: '#a6e3a1'
              toggleOffColor: '#a6adc8'
        dialog:
          fgColor: '#f9e2af'
          bgColor: '#9399b2'
          buttonFgColor: '#1e1e2e'
          buttonBgColor: '#7f849c'
          buttonFocusFgColor: '#1e1e2e'
          buttonFocusBgColor: '#f5c2e7'
          labelFgColor: '#f5e0dc'
          fieldFgColor: '#cdd6f4'
    '';
  };
}
