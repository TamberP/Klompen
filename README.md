# Klompen

Klompen is a static blog generation engine; that is to say, the only
active code run is on the blog-owner's desktop machine, removing one
avenue of attack -- and, possibly, some load -- from the server.

Klompen is user-friendly, but it is *very* particular in its selection
of friends.

I make no apologies for the friendliness, sanity and coherence -- or
the lack thereof -- of its actions, or interface; sorry.

## Dependencies

Currently, the tower of dependencies stands at:

- **JSON**
   *Configuration files*

- **DBI**
   *Database*

- **File::Spec**
   *Portable file & folder name manipulation*

- **File::Slurp**
   *Reading in, and writing out, files*

- **File::Copy**
   *Copying files*

- **Getopt::Std**
   *Options*

- **Time::localtime**
   *Time-related things*

- **common::sense**
   *Possibly the most important of all.*

## Usage

## Mongling the Database

There is a small tool for performing tasks such as the required adding
of authors and categories before creating a post. It will also create
the bare database for you.

Deletion is not supported.

    ./dbmod.pl -f <config> -[a|c|d]

Options:

- f : Config file to use.
- a : Add an author to the database. Arguments: 'username' 'realname'
  'email address' and 'web address'
- c : Add a category to the database. Arguments: 'category name'
  description'
- d : Create the bare database.

**Only one of a, c, or d may be performed at one time. You must create
the database before trying to add anything to it (duh), you must add
an author or category before you try to reference it with a post.**

## Creating Posts

Once the database is initially set up, consisting of creating
categories and author 'accounts', as well as making the appropriate
modifications to the configuration file; the process of creating a
blog post is as follows:

1. Create, as a markdown document, your blog-post proper. (For best
results, use UTF-8.)

2. Run blog.pl with the appropriate arguments, giving it the
directions to both your blog config file, and the post markdown source
file; as well as setting various items of metadata.

An example is given below:


    ./blog.pl -f ~/blog/config -a blog-user -s ~/post.txt \
    -t "My First Post" -c "personal,misc"

For a description of the somewhat randomly assigned flags, there is a
--help flag; which must be used on its own.

The blog.pl script will then perform a little validation, and add --
hopefully -- sane defaults where appropriate; before copying the
source post to the blog's source folder, and adding the appropriate
meta-data to the database.

## Generating the Site

Once posts have been added, the site needs to be generated to produce
something that can be uploaded to the web server; this, of course,
needs to be done with every change you make to your posts.

To create the site, run klomp.pl with its only option: the path to
the config file for the blog you wish to re-generate.

    ./klomp.pl -f ~/blog/config

This will then create a tree of HTML files, and folders, in the output
folder. The output will include:

+ Individual posts
+ Archive pages, reverse-chronologically ordered
  - Archive by month
  - Archive by tag
+ RSS feed

You can then upload this output folder to the web-server.
