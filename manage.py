#!/usr/bin/env python
import os
from dotenv import load_dotenv
load_dotenv()

import sys

if __name__ == "__main__":
    # os.environ.setdefault("DJANGO_SETTINGS_MODULE", "cms.settings.dev")
    DJANGO_SETTINGS_MODULE = os.environ["DJANGO_SETTINGS_MODULE"]

    from django.core.management import execute_from_command_line

    execute_from_command_line(sys.argv)
