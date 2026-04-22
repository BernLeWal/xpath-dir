# XPath for Moodle

XPath can be used to navigate through elements and attributes in an XML document. 
The same concept would be usable for all hierarchically structured data, like file systems - or in out case the moodle-course elements (and more) as file system.

Let's assume the current sample structure for moodle data
```
/courses
    - course [@id=4711, @name="QUELLKURS_S3_SWEN1", ...]
        - module [@id=1001, @name="General", ...]
            - topic [@id=22001, @shortname="Intro", @name="Introduction to subject",--]
                - activity [@id=12345, @type="Media", @desc="This topic is...."]
                - activity [@id=12346, @type="File", @title="C# Crash Course", @file="cs_intro.pdf"]
    - course [@id=4712, @name="QUELLKURS_S4_SWEN2", ...]
        - module [@id=1011, @name="General", ...]
            - topic [@id=23001, @shortname="Intro", @name="Introduction to subject",--]
                - activity [@id=22345, @type="Media", @desc="This topic is...."]
                - activity [@id=22346, @type="File", @title="ASP.Net Core", @file="aspnet_intro.pdf"]
    - course-4713 [@id=4713, @name="QUELLKURS_S5_SWEN3", ...]
    ...
```

The most useful path expressions are listed below:
| Expression (in *cursive*) | Description |
|---|---|
| *course* | Selects all nodes with the name "course" |
| */* |	Selects from the root node |
| *//* | 	Selects nodes in starting from the current node that match the selection no matter where they are |
| *.* | 	Selects the current node |
| *..* | 	Selects the parent of the current node |
| *@* | 	Selects attributes |

In the table below we have listed some path expressions and the result of the expressions:
| Path Expression |	Result |
|---|---|
| course | Selects all nodes with the name "course" |
| /courses | Selects the root element "courses" <br/> Note: If the path starts with a slash ( / ) it always represents an absolute path to an element! |
| courses/course |	Selects all course elements that are children of courses |
| //topic | Selects all topic elements no matter where they are |
| topic//activity |	Selects all activity elements that are descendant of the topic element, no matter where they are under the course element |
| //@type | Selects all attributes that are named type |


In the table below we have listed some path expressions with predicates and the result of the expressions:
| Path Expression | 	Result |
|---|---|
| /topic/activity[1] | 	Selects the first activity element that is the child of the topic element. |
| /topic/activity[last()] |	Selects the last activity element that is the child of the topic element |
| /topic/activity[last()-1] | 	Selects the last but one activity element that is the child of the topic element |
| /topic/activity[position()<3] |	Selects the first two activity elements that are children of the topic element |
| //activity[@type] |	Selects all the activity elements that have an attribute named type |
| //activity[@type='file'] |	Selects all the activity elements that have a "type" attribute with a value of "file" |
| /topic/activity[@size>3500] | 	Selects all the activity elements of the topic element that have a size attributed with a value greater than 3500 |
| /topic/activity/[@type='file' and @pages>10]/content |	Selects all the contents of the activity elements of the topic element that have a type attribute with a value of 'file' and a size attribute with a value greater than 3500 |


What we can do in our case:
* `//course/topic/activity[@type='file' and @title='*C#*']/file` ... returns all files which are in an activity having C# in the title
* `//course[topic/activity[@type='file' and @title='*C#*']]` ... returns all courses which have some activity on C#
