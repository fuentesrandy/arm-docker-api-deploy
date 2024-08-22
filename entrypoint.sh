#!/bin/bash
# Start supervisor, which will manage both the SSH server and the .NET app
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
