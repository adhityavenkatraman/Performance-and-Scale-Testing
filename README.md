Performance and Scale Testing
=============================

#### Introduction

Performance and scale (PnS) testing is essential to creating reliable,
scalable services for the cloud. This application offers a simple,
automated way for developers to test their APIs for performance and
scale. 

This program, pnstestapp.sh, utilizes JMeter, an open-source testing
tool, and runs from the command line. User input and test parameters are
fed into the program via .json files that are packaged with the script.
By using .json files, users can test several APIs at unique parameters.
Each test measures throughput at different thread levels to determine if
an API can continue to perform efficiently under increasing stress.
Threads simulate users making API calls. Tests increment threads until
the throughput either decreases or fails to experience a significant
increase (\> 5 bytes/second or \>10% of previous run). At that point,
the test stops and indicates the thread level at which the highest
throughput was achieved. Throughout the testing process, live summary
statistics for throughput, response time, latency, and errors will be
printed so that developers know exactly how well their API is running.
When one API has been tested, the tool will proceed to the next one.
After each test, a results file is also produced for each run.

Dependencies

There are a few tools that developers must download to run the program,
if they do not have them already. Many of these tools may already be
installed, but are listed below in case alone with relevant links to
read about/download them. 

-   **Bash**: The script is written in Bash.

-   **jq**: A .json parser.

    -   <https://stedolan.github.io/jq/download/>

-   **awk**: A command line calculation tool.

    -   <https://www.gnu.org/software/gawk/manual/html_node/index.html#SEC_Contents>

-   **bc**: Another calculation tool. 

    -   <https://www.gnu.org/software/bc/>

-   **JMeter**: The tool that runs these tests.

    -   <https://jmeter.apache.org>

    -   The JMeter will install as a folder
        titled apache-jmeter-\"version\". Place this folder inside an
        empty folder titled \"**jmeter**\". This is done to ensure that
        the script will continue to perform, even as new versions of
        JMeter are released. Ensure that the new **jmeter** folder is in
        the same directory as **[pnstestapp.sh]{.ul}**

Files

Along with the script itself, two additional files and one folder are
included: Test-Script.jmx, Test-Input.json, and BodyData. This include a
.jmx file that is populated by the script and interpreted by JMeter to
perform the tests, a .json file that contains basic API and test
information, and a folder that contains additional .json files for body
data carried by APIs. Because many process are automated by the script,
certain file naming conventions must be maintained for the script to
work. [Also, ensure that the **pnstestapp.sh**, the **Test-Script.jmx**
file, the **Test-Input.json** file, the **BodyData** folder, and the
**jmeter **folder are all in the same directory.]{.ul}

Of these files, only the contents of Test-Input.json and BodyData (which
contains more .json files) should be edited by the user. Again, users
avoid changing any file names and follow the above naming convention for
BodyData.

  **pnstestapp.sh**     When a user invokes the script, it will immediately begin the testing process. Before invoking the script, the .json files should be populated.
  --------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  **Test-Script.jmx**   Users should [not]{.ul} make any adjustments to this file. Simply ensure that it is within the same directory as pnstestapp.sh.
  **Test-Input.json**   Users should edit the contents of this file to input their API information and parameters here. The input file may be pre-loaded with a few sample APIs that can be replaced.
  **BodyData**          This folder contains body data for API calls that send information, like those that use a PUSH method. Within the folder, users will create a separate .json file containing the Body Data for each API that needs one. When creating new files, within BodyData, name each new file BodyData-X.json, where X is the index value of the corresponding API within the Test-Input.json, starting with 0. For example, if I am creating a .json file for the body of the first API in Test-Input.json, then the body file will be named BodyData-0.json. Maintain this naming convention to ensure that the each API is matched with the correct body data.

Configuring a Test

Once the script, the supplementary files, and the dependencies are
downloaded, users can begin configuring their tests by
editing **Test-Input.json **and **BodyData**.

The **Test-Input.json **file includes several different variables and
parameters that the user can set. There are 10 key-value pairs that
should be filled in for each API. Each API is a separate object. The
first six are string values that will be unique to each API:

-   testname: A string that the user can set to identify the results of
    each test when they are completed

-   apipath: The API Path

-   header: The API header

-   token: A token generated that enables one to access the API

-   clusterpath: The cluster from which the API calls should be made

-   method: The type of HTTP method to be made

The latter four are general test parameters, and have default values. In
the descriptions below, the default values are after the semicolon. If
the user intends to use the default values, these fields can remain
either blank or with the default values. If the user chooses to override
the defaults, then the script will proceed using the values specified
in **Test-Input.json.**

-   threads1: An initial thread count value; 5

-   threads2: A subsequent thread count value for initial comparison; 10

-   duration: Length of the test (seconds); 120

-   pods: The multiplier applied to increment the thread count; 2

The below image captures the structure of the **Test-Input.json **file.

![](media/image1.tmp){width="4.875in" height="3.7291666666666665in"}

The **BodyData **folder will contain multiple .json files. Because body
data is often stored in a .json format, there is generally no additional
formatting that needs to be done here.

See below for an example of both the file structure of
the **BodyData **folder and an example of what the body data looks like
within a BodyData-X.json file.

![](media/image2.tmp){width="4.875in" height="2.7604166666666665in"}

![](media/image3.png){width="4.875in" height="3.6354166666666665in"}

Running a Test
--------------

After the input data is configured, we can begin testing APIs. Below is
a walkthrough that demonstrates a complete test through several runs
with pictures and some brief commentary of how the program operates.

1.  After invoking the program, the test will automatically prompt the
    user if they wish to proceed with default values for the test. In
    this case, the user has selected No, so they will proceed with the
    defaults. Note that in Bash, selection of a menu requires the user
    to enter the numerical value of their answer in a list, rather than
    a string of the answer itself. Therefore, to select No, the user
    enters 2.\
    \
    ![](media/image4.png){width="4.875in"
    height="2.1979166666666665in"}![](media/image5.png){width="4.875in"
    height="2.1979166666666665in"}

2.  The test will then begin with 5 threads making API calls and will
    continue for the duration of the test (in this case 120 seconds).
    Every 30 seconds, the script will produce a live count of the number
    of calls, time elapsed, average throughput, response time (average,
    minimum, maximum), and a running error count. At the conclusion of
    the run, the script will produce relevant summary statistics to
    measure the performance of the API, such as the mean throughput, as
    well as the mean, median, 90th, and 95th percentile of latency.
    While throughput is the key dependent variable measured, the other
    values provide important measures for the success of the API run.\
    \
    ![](media/image6.png){width="4.875in" height="1.5in"}

3.  After completing the first run, the script will proceed to testing
    at the second default thread level of 10. After completing the run,
    the script will now produce a list of all the throughput values thus
    far and compare the most recent ones. This change in throughput,
    which is displayed for the user, determines if the test will
    continue. If the change is negative, the test will stop and declare
    that the second-most recent run was the optimal level. If the change
    is positive, but insignificant (below 5 bytes/second or 10% of the
    previous throughput) the test will halt and declare the most recent
    run to have the optimal thread level. These cutoffs were determined
    through conversations and guidance from QA engineers. If the
    throughput is both positive and significant, then the test will
    continue.\
    \
    ![](media/image7.png){width="4.875in" height="1.9270833333333333in"}

4.  At this point, the thread count will begin increasing by the pods
    multiplier. Because the default multiplier is 2, the test will now
    test the API at 20 threads.\
    \
    ![](media/image8.png){width="4.875in" height="2.0104166666666665in"}

5.  Eventually, the test will place sufficient stress on the API that it
    will no longer operate efficiently. At this point, the change in
    throughput will likely be less than 5 bytes/second or 10% of the
    previous run. In the example below, both of these conditions are
    met. Thus, the test is concluded, and the script indicates to the
    user that their API can handle 160 threads. \
    An important note is that the test will halt always halt at or
    before 200 threads. This is because the focus of the tool is to
    determine if the API can handle a certain threshold of stress,
    rather than to determine its breaking point. If an API can withstand
    200 threads, then it  effectively passes the performance and scale
    test. For this reason, under the default parameters, the test will
    always halt at 160, regardless of if the API can handle greater
    load. Even if other default thread counts are used, the test will
    always halt at or before 200.\
    \
    ![](media/image9.png){width="4.875in" height="2.375in"}

Post-Test Results
-----------------

A new \"results\" folder is created in the same directory that the
script is called from. Several comprehensive results files will populate
this folder as the tests progress. The testname variable assigned by the
user in the **Test-Inputs.json **file will be crucial to distinguishing
these files. Each result file name will include the date, time, and API
test name. In addition to the summary statistics and results that are
displayed live during each test, JMeter will produce these results as
.csv files that contain raw data for every single call that was made.
Each of these results files are populated live during the test, and are
complete as soon as the test is finished. Some data included is the
elapsed time, HTTP response code, sent bytes, latency, and connect time
for each call. This information will be relevant for any user who wants
to further explore their results or is interested in producing
additional statistics or conducting further analysis of their tests. To
do so within the Bash terminal, awk is recommended to parse the results
files or fill new columns with additional calculations. Below is a
sample results file.

![](media/image10.png){width="4.875in" height="3.5625in"}

For additional questions about this tool,
contact <avenkatraman22@cmc.edu.> 
