# Ruby Markdown Language

This is a superset of HTML, which allows for dynamically specifying the static content.

## Templating

RML allows for including other files. 
This can allow for DRY principles, where any content that is included in multiple pages can be included wherever necessary. 
This is done using `<ruby include="page_layout.rml">`.

RML also allows for blocks to be defined. They are started with `<ruby block-begin="blockname>` and ended with `<ruby block-end="blockname>`. 
The first instance of a block is the location that the final block inner content will end up within the document. 
You can also include the content of previous blocks using `<ruby block-super>`.

This allows for templating by using the following small example as a template, and then a specific page.

**`layout.rml`**
```html
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <title>Foo Bar</title>
    </head>
    <body>
        <header>
            <!-- Template Content -->        
        </header>
        <main>
            <ruby block-begin="main">
            <ruby block-end="main">
        </main>
        <footer>
            <!-- More Template Content -->
        </footer>
    </body>
</html>
```

**`page_1.rml`**
```html
<ruby include="page_layout.rml"> <!-- This defines the 'main' block previously in the document.  -->
<ruby block-begin="main"> <!-- And this contains the final content of the main block, unless another file overwrites it. -->
    <p>Some really fun content!</p>
<ruby block-end="main">
```

You can specify for layout pages (or any files) to not be generated into html files by using the `.genignore` file.

## Dynamism

You can run arbitrary ruby code inside `<ruby>` and `</ruby>` tags. 
The `p` function has been redefined to output its argument to the generated HTML file.

## HTML Convenience Functions

RML defines functions for all the HTML elements.

```html
<ruby>
    p DIV([
        P([
            "This is a first",
            EM("paragraph"),
            "that includes",
            A("a link", href: "https://google.co.uk")
        ], class: "highlighted underline")
    ])
</ruby>
```
