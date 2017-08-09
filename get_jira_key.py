#!/usr/bin/env python
#-*- coding:utf-8 -*-

import os
import sys
import re
import pprint

from netrc import netrc
from jira  import JIRA


def get_user_passwd():
  netrc_file = os.path.join(os.environ['HOME'], '.netrc')
  if os.path.exists(netrc_file):
    netrc_contents = netrc(netrc_file).hosts
  else:
    sys.exit('.netrc is not exists in %s' % os.environ['HOME'])

  jira_url= netrc_contents.keys()[0]
  user = netrc_contents[jira_url][0]
  passwd = netrc_contents[jira_url][-1]

  return jira_url, user, passwd

def _main():
  reload(sys)
  sys.setdefaultencoding('utf-8')

  args = args_parser()
  jira_id = args.jiraid
  version = args.version

  jira_url, user, passwd = get_user_passwd()
  jira = jira = JIRA(jira_url, basic_auth=(user, passwd))
  issue = jira.issue(jira_id)

#  transitions = jira.transitions(issue)
#  print [(t['id'], t['name']) for t in transitions]
  try:
    #jira.transition_issue(issue, '51', {"customfield_10274": version})
    #jira.transition_issue(issue, '61')
    projects = jira.projects()
    keys = sorted([project.key for project in projects])
    print [key for key in keys]

  except Exception as e:
    sys.exit(e)


if __name__ == '__main__':
  _main()
