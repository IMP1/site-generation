# Site Generator

This allows for the generation of static websites. It can process `rml` files, and `note` files. 

## Installation

*Coming Soon*

## Usage

You can specify a directory as the source and target.
You can also specify git branches to be sources and targets (and this works with one branch in a repo containing content, and another branch as the target for the generated content). This requires having git installed.

You can include a `.genignore` file whit will stop any files that match any of its filepath patterns from being generated.

## RML

RML is a markup language, which is a superset of HTML, adding in some special tags.

### Templating

RML allows for including other files. This can allow for DRY principles, where any content that is included in multiple pages can be included wherever necessary. This is done with the following code:

```
<ruby include="page_layout.rml">
```

RML also allows for blocks to be defined. They are started with `<ruby block-begin="blockname>` and ended with `<ruby block-end="blockname>`. The first instance of a block is the location that the final block inner content will end up within the document. You can also include the content of previous blocks using `<ruby block-super>`.

This allows for templating by using the following small example as a template, and then a specific page.

`layout.rml`
```
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

`page_1.rml`
```
<ruby include="page_layout.rml"> <!-- This defines the 'main' block previously in the document.  -->
<ruby block-begin="main"> <!-- And this contains the final content of the main block, unless another file overwrites it. -->
    <p>Some really fun content!</p>
<ruby block-end="main">
```

You can specify for layout pages (or any files) to not be generated into html files by using the `.genignore` file.

### Dynamism

You can run arbitrary ruby code inside `<ruby>` and `</ruby>` tags. The `p` function has been redefined to output its argument to the generated HTML file.

