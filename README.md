# Site Generator

This allows for the generation of static websites. It can process `rml` files, and `note` files. 

## Installation

*Coming Soon*

## Usage

You can specify a directory as the source and target.
You can also specify git branches to be sources and targets (and this works with one branch in a repo containing content, and another branch as the target for the generated content). This requires having git installed.

You can include a `.genignore` file whit will stop any files that match any of its filepath patterns from being generated.

`./generate --source /c/Users/huwtaylor/Projects/mir/wiki --source-branch content --target /c/Users/huwtaylor/Projects/mir/wiki --target-branch master`

## Supported Content Filetypes

All files that are not in the `.genignore` will be either copied, or converted, even images and binary files.

The filetypes that will be converted at the moment are `.rml`. 

**RML** is a markup language, which is a superset of HTML, adding in some special tags.
For more details, see [The RML Readme](https://github.com/IMP1/site-generation/blob/master/RML.md).

## Examples

I'm currently using this utility for [The Wiki](https://github.com/IMP1/mir-wiki) I'm making for my worldbuilding.

## Credits