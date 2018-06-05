# Klompen

Klompen is a static blog generation engine, with an ever growing tower
of dependencies.

## Dependencies
   - **HTML::Tiny** *HTML Generation*
   - **JSON** *State saving, configuration*
   - **File::Path** *Output folder creation*
   - **File::Slurp** *Reading in and writing out files*
   - **XML::RSS::SimpleGen** *RSS Feed generation*
   - **File::Spec** *File modification time, for incremental updates*
   - **Date::Format**
   - **Encode**
   - **utf8::all**
   - **Switch**

### Optional, depending on input formats
   - **Text::Markdown** *For when your input documents are Markdown formatted*
   - **Text::MediaWikiFormat** *Blog posts in MediaWiki formatting? Sure*
   - **Text::WikiCreole** *Creole Wiki Formatting? Okay!*

## Arguments

Only one, optional: Path to an alternate configuration file.

## Configuration

Configuration is per-blog, with the settings pulled from klompen.cfg
by default, or any named config file; a mostly self-explanatory JSON
file with the following:

### Options

* `site_name`
   Name of the site. Used for page titles, and so-forth.
* `base_url`
   URL the blog will be hosted at. (That is, if the blog will be in
   the folder blog/ at example.com; this should be
   http://example.com/blog/"
* `includes`
   Directory to look in for include files.
* `verbose`
   if set to `true`, debugging and informational messages are printed
   during the run.

### posts

This section contains the following:

#### Output

* `extension`
  Extension to give the output files. (The output generated by Klompen
  will be static HTML, but you may want to include PHP code in the
  header or footer; this is where you would change the extension to
  .php)
* `directory`
   Directory to output to. This may be relative or absolute. All other
   output will be relative to this.
* `encoding`
   Encoding that the output textfiles will be in. Defaults to the
   recommended utf-8.
* `incremental`
   Either 'true' or 'false'. Sets whether or not the modification time
   of the source file is used to determine if the output file should
   be re-generated. Defaults to 'false'; which will result in the
   regeneration of all output pages, whether or not the corresponding
   input file has changed.
* `snippet_length`
   Number of lines of the post to use as the post snippet; the text
   preview of the post, in the index listings.

##### `urls`

The following are relative to the output directory, and will -- where
required -- automatically have the base_url prepended.

* `stylesheet`
   Link to the stylesheet you want to use.
* `tags`
  Path, relative to the output directory, you want the tag/category
  files to be placed.
* `archives`
  Relative path to the location that posts will be output to.
* `rss`
   Name of file where the RSS feed is generated.
* `author_info`
  Location where author profile pages will be stored.

#### `input`

 *** Currently, there is no option to allow you to relocate the author
  profile/info page source directory; I'll add this soon. ***

* `extension`
  File extension to use to find source posts when scanning
  the source dir (This can be blank if your source posts
  don't have a file extension on them.)
* `directory`
   Folder to scan for source posts in.
* `format`
   Default markup format to use. (Can be overridden in individual posts.) Valid options are: `markdown`, `creole`, `wiki`.
* `encoding`
  Character encoding to expect input files in.

### links

This part of the config is an array of links, which will be added to
the 'links' section of the output page's sidebar. See the example
config.

## Using

To use Klompen, you create your posts as plain text files (Preferably
UTF-8 encoded.), formatted using one of three mark-down formats:

 - [Markdown](https://daringfireball.net/projects/markdown/) The
   initial, and default formatting type.
 - [MediaWiki](http://en.wikipedia.org/wiki/Help:Contents/Editing_Wikipedia) Wikipedia-style formatting.
 - [WikiCreole](http://www.wikicreole.org/wiki/Creole1.0) Creole 1.0 markup.

Using the header to provide metadata such as the post's title, the
date of publication, the list of tags/categories (comma separated) and
-- optionally -- the post's ID.

The post's ID will be automatically added, if it's not manually
inserted, incremented each time. However, it is possible to control
the post's ID by setting it manually, which may be useful to some
users; such as those transferring a blog from, e.g. Wordpress, so that
you may put your existing posts at the same post IDs as they were
under WP.

The article template (doc/article_template) has the basic header, so
that you can use a copy to create your own post files. However, the
header format is explained below.

When you have your finely crafted post ready to publish (or update),
run 'klompen' (After, of course, configuring it correctly.), and all
posts (Only files modified since the last run, if the incremental
option is set.) will be converted into a HTML page in the output
directory, with pages to list posts by category, and an RSS feed.

### Header Format

The header must be the first thing in the document, and terminated by
a line containing only: `--text follows this line--`.

Each piece of metadata is a line starting with the name of the
metadata, followed by a colon, and then the value that you're setting
it to.

#### Title

For example, setting the title of a post is pretty simple:

    Title: An Example Blog Post

#### Author

Posts should generally have an author name given, though it is only
used for a profile page. For example, to list your post as belonging
to Fred...

    Author: Fred

The name may be followed by an email address, in a similar form to the
example post in the documents folder; however, it is not required, or
even currently used.

#### Tags

To add tags to a post, they should be added in a comma-separated line
as such:

    Tags: example, tag, list

#### Dates

When creating a post, in order for it to be sorted by publication
date, you obviously need to add a date; this is done in a similar
manner to the other forms of metadata:

    Date: <date>

This piece of metadata is rather flexible as to how the date is
formatted; but the One True Date Format is the ISO 8601 format:
YYYY-MM-DDTHH:mm:ss+ZZ:ZZ (Where 'T' is a literal 'T', and +ZZ:ZZ is
the timezone offset from UTC.)

You may to add a new Date line each time the post is edited; the first
will be used as the publication date, and each afterwards may be used
to insert a "<Post> edited" stub at the correct point in the archives.

#### Format

If you wish to specify that a source file is in a different format to
the default, specify:

    Format: <format>

The currently accepted options for format are:

 * `markdown`
 * `creole`
 * `wiki`

#### Post ID

The post ID does not have to be manually inserted, and conflicts (Two
posts with the same ID.) will cause undefined behaviour (Nasal demons,
I tell you!). However, if you are migrating from WordPress to Klompen
and wish to keep your existing posts at the same URL (So long as you
haven't use pretty URLs. If you have, you're on your own.), you may
specify post IDs when 'importing' your posts.

The ID is simply a unique autoincrementing integer, used to reference
the post in the archives.

#### Example

For example, if Fred wished to convert over his example blog post from
WordPress where it was -- for sake of argument -- post ID 43, and he
wrote his source file in Creole markup; he'd use the following header:

    ID: 43
    Title: An Example Blog Post
    Author: Fred
    Tags: example, tag, list
    Date: 2014-04-19T21:02:27+01:00
    Format: creole
    --text follows this line--
