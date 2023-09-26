#!/usr/bin/python

# ==================================================================
# dialog.py
# ==================================================================
# Dialog Dojo Installer
#
# File:         dialog.py
# Author:       Ragdata
# Date:         14/09/2023
# License:      MIT License
# Copyright:    Copyright © 2023 Darren (Ragdata) Poulton
# ==================================================================
# DEPENDENCIES
# ==================================================================
import os
from tempfile import mktemp
from time import sleep

DIALOG = os.getenv("DIALOG")
if DIALOG is None:
	DIALOG = "/usr/bin/dialog"


class Dialog:
	def __init__(self):
		self.__bgTitle = ''
		self.__title = ''
		self.__ok_label = 'OK'
		self.__cancel_label = 'Cancel'
		self.__height = '10'
		self.__width = '40'

	def setBackgroundTitle(self, text):
		self.__bgTitle = '--backtitle "%s" ' % text

	def setTitle(self, text):
		self.__title = '--title "%s" ' % text

	def setOKLabel(self, text):
		self.__ok_label = '--ok-label "%s" ' % text

	def setCancelLabel(self, text):
		self.__cancel_label = '--cancel-label "%s"' % text

	def __buildBox(self, cmd):
		fileName = mktemp()
		box = os.system('%s %s %s 2> %s' % (DIALOG, self.__bgTitle, cmd, fileName))
		f = open(fileName)
		output = f.readlines()
		f.close()
		os.unlink(fileName)
		return box, output

	@staticmethod
	def __buildBox_noOptions(cmd):
		return os.system(DIALOG + ' ' + cmd)

	@staticmethod
	def __handleTitle(title):
		if len(title) == 0:
			return ''
		else:
			return '--title "%s" ' % title

	@staticmethod
	def __handleSeparator(separator):
		if len(separator) == 0:
			return ''
		else:
			return '--separator "%s" ' % separator
