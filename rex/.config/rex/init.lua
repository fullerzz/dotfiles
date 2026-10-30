-- Rex configuration: https://www.superlogical.com/rex/docs/customize/config

rex.bind("ctrl+a>c", "client.tab.new")
rex.bind("ctrl+a>n", "client.tab.next")
rex.bind("ctrl+a>p", "client.tab.previous")
rex.bind("ctrl+a>shift+5", "pane.split", { direction = "right" })
rex.bind("ctrl+a>shift+'", "pane.split", { direction = "down" })
rex.bind("ctrl+a>z", "pane.zoom")
rex.bind("ctrl+a>x", "pane.close")

-- Press Ctrl+A twice to send Ctrl+A to the terminal.
rex.bind("ctrl+a>ctrl+a", "pane.send_key", { key = "ctrl+a" })
