# XPath Directory (xpath-dir)
**xpath-dir** is a executable linux bash shell script which allows to query file directory structures of the underlying operating system based on the XPath syntax, known by the W3C specification to query XML-based data.

Syntax: xpath-dir <query-string>

## Introduction

- **xpath-dir** can be used to navigate through files, directories and their attributes in the underlying linux file system.
- **xpath-dir** uses path expressions to select file/dir-infos or sets of file/dir-infos in a file system
- **xpath-dir** includes alre build-in functions. There are functions for string values, numeric values, booleans, date and time comparison, file/dir-info manupulation, sequence manipulation and much more. 

## Nodes
- In **xpath-dir**, there are the following kinds of **nodes**: file, directory, attribute and root-nodes.
- The file system is treated as trees of nodes. The topmost element of the tree is called the root-node.

    Look at the following example (generate with the `tree -L 3 ~` command):
    ```sh
    ~
    ├── app
    │   └── index.php
    ├── build.sh
    ├── index.php -> ~/app/index.php    
    ├── LICENSE
    ├── README.md
    ├── run.sh
    └── static
        ├── assets
        │   ├── css
        │   ├── fonts
        │   └── js
        ├── elements.html
        ├── favicon.ico
        ├── generic.html
        ├── images
        │   ├── banner.png
        │   ├── pic01.jpg
        │   ├── pic02.jpg
        │   └── logo.png
        └── index.html
    ```

    Examples of nodes in the file-system above:
    * `~` ... root-node
    * `app` ... directory
    * `README.md` ... file

    Look at the following example, using the `ls -al ~` command to get the attributes:
    ```sh
    drwxr-xr-x 8 group user 4096 Apr 22 11:34 .
    drwxr-xr-x 5 group user 4096 Jan 24 17:23 ..
    drwxr-xr-x 2 group user 4096 Jul 18  2025 app
    -rwxr-xr-x 1 group user  418 Jul 18  2025 build.sh
    lrwxrwxrwx 1 group user   48 Apr 22 11:34 index.php -> ~/app/index.php
    -rwxr-xr-x 1 group user 1074 Jul 18  2025 LICENSE
    -rwxr-xr-x 1 group user 1970 Jul 18  2025 README.md
    -rwxr-xr-x 1 group user  281 Jul 18  2025 run.sh
    drwxr-xr-x 4 group user 4096 Jul 18  2025 static
    ```

    Examples of attributes in the file-system above (first line explained, a line is a node). Each column represents an attribute:
    * `drwxr-xr-x` ... **is-dir/is-file**, and owner/group/all **rights**
    * `8` ... the **number of items** including sub-items. If it is a file it is 1. If it is a directory it is the number of items stored in that directory
    * `group` ... the **group** to which the node belongs, here "group"
    * `user` ... the **user** to which the node belongs, here "user"
    * `4096` ... the **size** of the file/directory in bytes
    * `Apr 22 11:34` ... the **date/time** of the last modification of that node. Could also be in format `Jul 18  2025`
    * `.` ... the **name** of the file or directory

- **Atomic values** are nodes with no children or parent, e.g. "en", 1000, true
- **Items** are atomic values of nodes.
- Relationship of nodes:
    - **Parent**: each file, directory and attribute has one parent.
    - **Children**: nodes may have zero, one or more children. Files and attributes have no children.
    - **Siblings**: Nodes that have the same parent.
    - **Ancestors**: A node's parent, parent's parent, etc.
    - **Descendants**: A node's children, children's children, etc.

## Query String Syntax

### Selecting Nodes

It uses path expressions to select nodes in a file system. The node is selected by following a path or steps. 

The most useful path expressions are listed below:
| Expression (in *cursive*) | Description |
|---|---|
| *nodename* | Selects all nodes with the name "nodename" |
| */* |	Selects from the root node |
| *//* | 	Selects nodes in the file-system from the current node that match the selection no matter where they are |
| *.* | 	Selects the current node |
| *..* | 	Selects the parent of the current node |
| *@* | 	Selects attributes |

Remark: *//*
Important: to optimize the speed to query with xpath-dir it is required that the linux package "locate" is pre-installed. Every time the *//* expression is used, the script should use the `locate ` command instead of the `ls `command.

In the table below we have listed some path expressions and the result of the expressions:
| Path Expression |	Result |
|---|---|
| static | Selects all nodes with the name "static" |
| /static | Selects the root element "static" <br/> Note: If the path starts with a slash ( / ) it always represents an absolute path to an element! |
| static/assets |	Selects all assets elements that are children of static |
| //static | Selects all static elements no matter where they are in the file system |
| static//asset |	Selects all asset elements that are descendant of the static element, no matter where they are under the static element |
| //@size | Selects all attributes that are named size |

### Predicates

Predicates are used to find a specific node or a node that contains a specific value.
Predicates are always embedded in square brackets.

In the table below we have listed some path expressions with predicates and the result of the expressions:
| Path Expression | 	Result |
|---|---|
| /static/asset[1] | 	Selects the first asset element that is the child of the static element. |
| /static/asset[last()] |	Selects the last asset element that is the child of the static element |
| /static/asset[last()-1] | 	Selects the last but one asset element that is the child of the static element |
| /static/asset[position()<3] |	Selects the first two asset elements that are children of the static element |
| //title[@user] |	Selects all the title elements that have an attribute named lang |
| //title[@user='John'] |	Selects all the title elements that have a "lang" attribute with a value of "John" |
| /static/asset[@size>3500] | 	Selects all the asset elements of the static element that have a size attributed with a value greater than 3500 |
| /static/asset[@size>3500]/title |	Selects all the title elements of the asset elements of the static element that have a size attribute with a value greater than 3500 |

### Selecting Unknown Nodes

Wildcards can be used to select unknown XML nodes.
| Wildcard | 	Description |
|---|---|
| * |	Matches any element node |
| @* |	Matches any attribute node |
| node() |Matches any node of any kind |

In the table below we have listed some path expressions and the result of the expressions:
| Path Expression |	Result |
|---|---|
| /static/* | 	Selects all the child element nodes of the static element |
| //* |	Selects all elements in the file system |
| //asset[@*] |	Selects all asset elements which have at least one attribute of any kind |

### Operators

Operators

Below is a list of the operators that can be used in XPath expressions:
| Operator | 	Description 	| Example|
|---|---|---|
| \| |	Computes two node-sets 	| //book \| //cd |
| + |	Addition |	6 + 4
| - |	Subtraction |	6 - 4
|* 	| Multiplication |	6 * 4
| div |	Division |	8 div 4
| = |	Equal |	price=9.80
| != |	Not equal |	price!=9.80
| < |	Less than |	price<9.80
| <= |	Less than or equal to |	price<=9.80
| > |	Greater than |	price>9.80
| >= |	Greater than or equal to |	price>=9.80
| or |	or 	| price=9.80 or price=9.70
| and |	and |	price>9.00 and price<9.90
| mod |	Modulus (division remainder) 	|5 mod 2

Attention: For the implementation of operators recherche for bash tools which already can achieve that. Don't implement by yourself to keep the script short.

## References

* [W3C Schools - XPath Syntax](https://www.w3schools.com/xml/xpath_syntax.asp)