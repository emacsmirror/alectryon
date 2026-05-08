==================
 Body-only output
==================

To compile::

   alectryon --body-only body_only.rst -o body_only.body.html
       # reST → HTML; produces ‘body_only.body.html’
   alectryon --body-only --backend latex body_only.rst -o body_only.body.tex
       # reST → LaTeX; produces ‘body_only.body.tex’

``--body-only`` keeps only the document’s body (no ``<html>``/``<head>`` for HTML, no preamble or ``\begin{document}`` for LaTeX):

.. coq::

   Print nat.
