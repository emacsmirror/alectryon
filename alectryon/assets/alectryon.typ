// Alectryon Typst support library

#let alectryon-json-version = 1

//// Theme

#let tango-light-aluminium = rgb("#EEEEEC")
#let tango-medium-aluminium = rgb("#D3D7CF")
#let tango-medium-gray = rgb("#555753")
#let tango-scarletred = rgb("#EF2929")

#let alectryon-fill-color = tango-light-aluminium
#let alectryon-stroke-color = tango-medium-aluminium
#let alectryon-goal-line-color = tango-medium-gray
#let alectryon-stale-warning-color = tango-scarletred

// LaTeX dimensions are set once and not rescaled within the output boxes
#let alectryon-output-scale = 0.9
#let alectryon-io-vsep = 1em // Match LaTeX
#let alectryon-margin = 0.3em / alectryon-output-scale
#let alectryon-vsep = 0.15em / alectryon-output-scale
#let alectryon-rule-skip = 0.3em / alectryon-output-scale
#let alectryon-hyp-h = 2em / alectryon-output-scale
#let alectryon-hyp-v = 0.6em / alectryon-output-scale
#let alectryon-hyp-indent = 0.3em / alectryon-output-scale
#let alectryon-marker-stroke = 0.4pt

//// Utilities

// Typst hardcodes `size: 0.8em` on `raw` elements
#let raw-correction = 1em / 0.8

// Math unit from LaTeX
#let mu = 1em / 18

#let txt = raw

// Current language, set by the show rule in `setup` and read by code()
#let _lang = state("alectryon-lang", "coq")

// kind → list of entries (indexed by call position)
#let _marker-info = state("alectryon-marker-info", ("mrefs": (), "mquotes": ()))

/// Render a single `marker`.
#let mref-marker(marker) = {
  sym.space.nobreak + box( // https://github.com/typst/typst/issues/4629
    stroke: alectryon-marker-stroke,
    inset: alectryon-marker-stroke / 2 + 0.1em,
    baseline: alectryon-marker-stroke / 2 + 0.1em,
    text(size: 0.8em, weight: "bold", marker)
  )
}

/// Render a list of `markers`.
#let mref-markers(markers) = {
  for m in markers { mref-marker(m) }
}

/// Wrap `contents` with `ids` as Typst labels.
#let with-ids(contents, ..ids) = {
  contents
  for id in ids.pos() [#metadata(none)#label(id)]
}

/// Wrap `contents` with `markers`.
#let with-markers(contents, ..markers) = {
  contents
  mref-markers(markers.pos())
}

/// Wrap `contents` in a `raw` block.
#let code(contents) = context {
  let lang = _lang.get()
  raw(contents, lang: lang)
}

/// Wrap `body` in a top-aligned inline box (LaTeX's ``\parbox[t]``).
/// See https://github.com/typst/typst/issues/493.
#let top-box(body) = context {
  let total = measure(body).height
  let single-line = measure(code("X")).height
  box(baseline: total - single-line, body)
}

/// Wrap `body` (multiple goals or messages) in a frame.
/// See https://github.com/typst/typst/issues/5741.
#let outputs(body) = block(
  fill: alectryon-stroke-color,
  inset: alectryon-margin,
  width: 100%,
  breakable: true,
  spacing: alectryon-vsep,
  body,
)

/// Wrap `body` (a single goal or message) in a frame.
#let output(body) = block(
  fill: alectryon-fill-color,
  inset: alectryon-margin,
  width: 100%,
  breakable: true,
  spacing: alectryon-margin,
  body,
)

//// Rendering primitives

/// Render an annotated block (one or more sentences with goals & messages).
#let io(body) = {
  v(alectryon-io-vsep)
  block(spacing: alectryon-io-vsep, {
    set par(justify: false)
    // Adjust font size of plain text items
    set text(size: raw-correction)
    // Adjust font size of code
    show raw: set text(size: raw-correction)
    body
  })
  v(alectryon-io-vsep)
}

/// Render a type or body preceded by its operator (`:`/`:=`)
#let _hyp-bt(op, term) = {
  if term != none {
    top-box({
      h(3 * mu) + op + h(4 * mu)
      top-box(term)
    })
  }
}

/// Render a single hypothesis with `names`, `body`, and `type`.
#let hyp(names, body, type) = {
  h(alectryon-hyp-h, weak: true)
  top-box(
    par(hanging-indent: alectryon-hyp-indent, {
      strong(names)
      _hyp-bt(txt(":="), body)
      _hyp-bt(txt(":"), type)
    })
  )
}

/// Render `contents` with height 0.
/// See https://github.com/typst/typst/issues/8162.
#let smash(contents) = context {
  let h = measure(contents).height
  box(height: 0pt, clip: false, box(height: h, contents))
}

#let _goal-separator(name, markers) = {
  v(alectryon-rule-skip)
  block(spacing: alectryon-rule-skip, {
    grid(
      columns: (1fr, auto, auto),
      column-gutter: 0pt,
      align: horizon,
      line(length: 100%, stroke: 0.4pt + alectryon-goal-line-color),
      if name != none { text(size: 0.75em, txt(" ") + name) },
      // For goals, markers appear next to the rule
      if markers != () { smash(mref-markers(markers)) }
    )
  })
  v(alectryon-rule-skip)
}

/// Render one goal with `name`, `hyps`, `concl`, and `markers`.
#let goal(name, hyps, concl, ..markers) = {
  output({
    if hyps != none {
      context par(leading: par.leading + alectryon-hyp-v, hyps)
    }
    _goal-separator(name, markers.pos())
    concl
  })
}

/// Render a single message.
#let message = output

/// Render a list of goals.
#let goals = outputs

/// Render a list of messages.
#let messages = outputs

/// Render one sentence with `input`, `outputs`, and `markers`.
#let sentence(input, outputs, ..markers) = {
  input + mref-markers(markers.pos())
  if outputs != none {
    set text(size: alectryon-output-scale * 1em)
    // LaTeX adds space relative to the bottom of the previous box; Typst uses
    // the baseline.  Compromise by adding half of a strut depth to vsep.
    block(spacing: 0.3em / 2 + alectryon-vsep, {
      outputs
    })
  }
}

/// Concat `args`.
#let concat(..args) = {
  args.pos().sum(default: none)
}

#let nodes = (
  io: io, sentence: sentence,
  goals: goals, goal: goal, hyp: hyp,
  messages: messages, message: message,
  code: code, txt: txt, "+": concat,
  id: with-ids, marker: with-markers,
)

/// Interpret an Alectryon JSON `node` into a Typst fragment.
#let render(node) = {
  if node == none or type(node) == str {
    node
  } else {
    let fn = nodes.at(node.first())
    let args = node.slice(1).map(render)
    fn(..args)
  }
}

/// Show `original` with a stale-snippet warning.
#let stale-warning(original) = block(
  fill: alectryon-stale-warning-color, inset: alectryon-margin, width: 100%,
  [*Stale snippet*: re-run `alectryon`. \ #original]
)

//// Main entry point

#let first-line-re = regex("^(.*?)(?:\n|\\z)")
#let fence-re = regex("^[{]([a-z0-9]+)[}]$")

/// Parse the `{…}` fence out of a raw element `it`.
///
/// Typst <= 0.14.2 doesn't recognize ``{coq}``, so we look for a
/// ``{...}`` language tag at the beginning of the body if the real
/// language tag is missing.
#let read-lang-tag(it) = {
  let lang = it.at("lang", default: none)
  let text = it.text

  if lang == none {
    // LATER: Discard this branch
    let line0 = text.match(first-line-re)
    if line0 == none { return (none, none) }
    (lang, text) = (line0.captures.at(0), text.slice(line0.end))
  }

  let fence = lang.match(fence-re)
  if fence == none { return (none, none) }
  (fence.captures.at(0), text)
}

//// Marker references, quotes, and assertions

#let _is-query-mode = {
  sys.inputs.at("alectryon-mode", default: none) == "query"
}

// Counters used to step through JSON data
#let _mref-counter = counter("alectryon-mref-idx")
#let _mquote-counter = counter("alectryon-mquote-idx")
#let _block-counter = counter("alectryon-block-index")

#let _resolve-marker(kind, fn, counter, path, ..values) = {
  if _is-query-mode {
    [#metadata((path: path, ..values.named()))#label("alectryon-" + kind)]
    return
  }
  if fn == none { return }

  context {
    let idx = counter.get().first()
    let entry = _marker-info.get().at(kind).at(idx, default: none)
    if entry == none or entry.path != path { // Stale Alectryon data
      text(fill: alectryon-stale-warning-color, [?#raw(path)?])
    } else {
      fn(entry)
    }
  }
  counter.step()
}

#let _mref(entry) = {
  link(label(entry.id), entry.marker)
}

/// Link to `path`.
///
/// - path: a value in the marker placement mini-language
/// - title: marker label to insert next to the object matching `path`
/// - prefix: prefix prepended to `path`; useful with ```typ .with```
/// - counter-style: counter style for the marker (e.g. ``"lower-greek"``)
#let mref(path, title: none, prefix: none, counter-style: none) = {
  _resolve-marker("mrefs", _mref, _mref-counter,
    path, title: title, prefix: prefix, counter-style: counter-style
  )
}

#let _mquote(entry, language: none, block: false) = {
  let lang = if language != none { language } else { entry.lang }
  _lang.update(lang)
  if block { render(entry.rendered) } else { box(render(entry.rendered)) }
}

/// Copy the object at `path`.
///
/// - path: a value in the marker placement mini-language
/// - prefix: prefix prepended to `path`; useful with ```typ .with```
/// - language: the language to render the quoted object in
/// - block: whether to render as a block (`true`) or inline (`false`)
#let mquote(path, prefix: none, language: none, block: false) = {
  _resolve-marker("mquotes", _mquote.with(language: language, block: block),
    _mquote-counter,
    path, prefix: prefix
  )
}

/// Assert that `path` resolves correctly.
/// Useful to check that a command's output has the expected shape.
///
/// - path: a value in the marker placement mini-language
/// - prefix: prefix prepended to `path`; useful with ```typ .with```
#let massert(path, prefix: none) = {
  _resolve-marker("masserts", none, none, path, prefix: prefix)
}

/// Initialize Alectryon support and load recorded output from `json-path`.
///
/// Use as ```typ #show: setup.with("/<filename>.alectryon.json")```.
///
/// - json-path: path to the `.alectryon.json` file produced by running
///   `alectryon --backend snippets-typst` on the current file.
#let setup(json-path, body) = {
  if _is-query-mode {
    // Skip processing when running in query mode
    return body
  }

  if json-path == none {
    return body
  }

  let js = json(json-path)
  if js.at("version") != alectryon-json-version {
    panic([`alectryon.typ` version #str(alectryon-json-version) does not match
      #json-path version #repr(js.at("version")); re-run `alectryon`.])
  }

  _marker-info.update(js.at("marker-info"))
  let snippets = js.at("snippets")

  show raw.where(block: true): it => {
    let (lang, text) = read-lang-tag(it)
    if lang == none { return it }
    context {
      let idx = _block-counter.get().first()
      let entry = snippets.at(idx, default: (src: "", lang: "", rendered: none))
      if entry.src != text or entry.lang != lang {
        stale-warning(it)
      } else {
        _lang.update(entry.lang)
        render(entry.rendered)
      }
    }

    _block-counter.step()
  }

  body
}
