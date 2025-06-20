#import "tools/headings.typ": set-heading-titles, structural-heading-titles
#import "tools/annexes.typ": is-heading-in-annex
#import "tools/pageframe.typ": page-frame-sequence
// #import "tools/utils.typ": is-empty
#import "tools/base.typ": *
#import "@preview/t4t:0.4.3":is-empty

#let enum-set-heading-numbering(doc) = {
  set enum(
    numbering: (..n) => context {
      let headings = query(selector(heading).before(here()))
      let last = headings.at(-1)
      counter(heading).step(level: last.level + n.pos().len())
      context { counter(heading).display() }
    },
  )
  doc
}

#let enum-drop-heading-numbering(doc) = {
  set enum(numbering: "1")
  doc
}

#let set-correct-indent-list-and-enum-items(doc) = {
  let first-line-indent() = if type(par.first-line-indent) == dictionary {
    par.first-line-indent.amount
  } else {
    par.first-line-indent
  }

  show list: li => {
    for (i, it) in li.children.enumerate() {
      let nesting = state("list-nesting", 0)
      let indent = context h((nesting.get() + 1) * li.indent)
      let marker = context {
        let n = nesting.get()
        if type(li.marker) == array {
          li.marker.at(calc.rem-euclid(n, li.marker.len()))
        } else if type(li.marker) == content {
          li.marker
        } else {
          li.marker(n)
        }
      }
      let body = {
        nesting.update(x => x + 1)
        it.body + parbreak()
        nesting.update(x => x - 1)
      }
      let content = {
        marker
        h(li.body-indent)
        body
      }
      context pad(left: int(nesting.get() != 0) * li.indent, content)
    }
  }

  show enum: en => {
    let start = if en.start == auto {
      if en.children.first().has("number") {
        if en.reversed { en.children.first().number } else { 1 }
      } else {
        if en.reversed { en.children.len() } else { 1 }
      }
    } else {
      en.start
    }
    let number = start
    for (i, it) in en.children.enumerate() {
      number = if it.has("number") { it.number } else { number }
      if en.reversed { number = start - i }
      let parents = state("enum-parents", ())
      let indent = context h((parents.get().len() + 1) * en.indent)
      let num = if en.full {
        context numbering(en.numbering, ..parents.get(), number)
      } else {
        numbering(en.numbering, number)
      }
      let max-num = if en.full {
        context numbering(en.numbering, ..parents.get(), en.children.len())
      } else {
        numbering(en.numbering, en.children.len())
      }
      num = context box(
        width: measure(max-num).width,
        align(right, text(overhang: false, num)),
      )
      let body = {
        parents.update(arr => arr + (number,))
        it.body + parbreak()
        parents.update(arr => arr.slice(0, -1))
      }
      if not en.reversed { number += 1 }
      let content = {
        num
        h(en.body-indent)
        body
      }
      context pad(left: int(parents.get().len() != 0) * en.indent, content)
    }
  }
  doc
}

#let style-ver-1(doc) = {
  let header-counter = counter("header-all")
  set page(margin: (left: 30mm, rest: 25mm))
  set text(lang: "ru", font: "Times New Roman", size: 13pt)
  set heading(numbering: "1.1.1")
  set list(marker: [–])
  set ref(supplement: none)
  set math.equation(numbering: "(1)")
  set figure.caption(separator: " — ")

  set par(
    first-line-indent: (
      amount: 1.25cm,
      all: true,
    ),
    justify: true,
  )

  show: set-base-style.with()

  show outline.entry: it => {
    if is-heading-in-annex(it.element) {
      link(
        it.element.location(),
        it.indented(
          none,
          [Приложение #it.prefix() #it.element.body]
            + sym.space
            + box(width: 1fr, it.fill)
            + sym.space
            + sym.wj
            + it.page(),
        ),
      )
    } else {
      it
    }
  }

  show heading: it => block(width: 100%)[
    #if not is-empty(it.numbering) {
      counter(heading).display(it.numbering) + [ ] + [#it.body]
    } else { it }
    #v(1cm)

  ]

  show image: set align(center)
  show figure.where(kind: table): set figure.caption(position: top)
  // show figure.where(kind: table): it => {
  //   set figure.caption(position: top)
  //   it
  // }

  show figure: it => block(if it.has("caption") {
    show figure.caption: caption => {
      set align(left)
      set par(first-line-indent: (amount: 0cm))
      if caption.numbering != none {
        caption.supplement + [ ]
        numbering(caption.numbering, ..counter(figure).at(it.location())) + [ \- ] + caption.body
        v(-2mm)
      }
    }
    it
  })


  show: set-heading-titles
  show: set-correct-indent-list-and-enum-items
  show heading: it => {
    if it.level == 1 {
      (
        pagebreak(weak: true)
          + block(
            it,
            fill: color.hsl(200deg, 15%, 75%, 30%),
            above: 12pt,
            below: 18pt,
            inset: 1mm,
            radius: 1mm,
          )
      )
    } else { it }
    header-counter.step()
  }
  doc
}
