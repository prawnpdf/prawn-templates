# Prawn Templates

[![Gem Version](https://badge.fury.io/rb/prawn-templates.svg)](http://badge.fury.io/rb/prawn-templates)
[![Build Status](https://travis-ci.org/prawnpdf/prawn-templates.svg?branch=master)](https://travis-ci.org/prawnpdf/prawn-templates)
[![Code Climate](https://codeclimate.com/github/prawnpdf/prawn-templates/badges/gpa.svg)](https://codeclimate.com/github/prawnpdf/prawn-templates)
![Maintained: PRs accepted](https://img.shields.io/badge/maintained-PRs_accepted-orange.svg)

Support for templates was dropped in Prawn 0.13.0, 
disabled by default in 0.14.0, and extracted in 0.15.0.

This gem includes the extracted templates code, which is mainly 
unsupported, but provides the old functionality that was in
Prawn 0.12.0 for years.

Templates were originally written by James Healy, but are no
longer actively maintained by anyone. Burkhard Vogel created 
a port to make the old code work again with the current state 
of prawn. Use at your own risk, or volunteer to help maintain 
the code through issues and pull requests or on the Prawn 
Mailing list:

https://groups.google.com/forum/#!forum/prawn-ruby

Keep in mind the reason that this gem was extracted is because the 
code is very buggy! For a list of old issues that were affecting
it, see Prawn's tracker:

https://github.com/prawnpdf/prawn/issues?direction=desc&labels=templates&page=1&sort=updated&state=closed

Issues that affect releases after 0.0.3 should be filed here.

For Prawn 2.1.0 use v0.0.4, Prawn 2.2.1 works with 0.0.5, if you rely on
pdf-reader 2.0 you should opt for 0.1.0. Although the gem requires ruby
versions after 1.9.3 only the ones mentioned in `.travis.yml` are
supported.
