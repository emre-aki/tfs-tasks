`CheckQualityGateStatus` build task helps check and determine if the current Quality Gate status is valid or not for any SonarQube project you specify. Also, you may specify within the task to break the build if the related Quality Gate is not satisfied. 

By default, SonarQube has no support of breaking pull request builds on a Quality Gate failure. This extension helps you achieve that, and not allow completing the affected pull requests and merging any branches that will possibly introduce new issues into your project.


> *Please make sure you have conducted at least one "full" SonarQube analysis on the branch whose Quality Gate status you are  about to check. Also, note that this task could be called only from build definitions intended for PR builds.*


## Requirements
- `npm`
- [`tfx-cli`](https://github.com/Microsoft/tfs-cli), a cross-platform CLI for VSTS/TFS
- Authentication to install/modify build extensions in TFS

## Setup
Once you've downloaded and unpacked the extension, `cd` into it. Then run the following command to log into your VSTS/TFS account.
```sh
$ tfx login
```
You can also specify an authentication method by passing it as an the argument to the command. Accepted values are `basic` and `pat`.
```sh
$ tfx login --auth-type basic
```
Then execute the following command to upload the extension to your build environment.
```sh
$ tfx build tasks upload --task-path .
```

## Configuring Build Task
Once you've uploaded the build task, you should be able to access it through your VSTS/TFS build environment. Create a new build definition, and navigate into it. Then search for the newly uploaded extension, you should be able to add it as a build task in your build definition.

<img src="https://github.com/emre-aki/tfs-tasks/blob/master/img/tasks.png?raw=true" width="800">

Make sure you place the task *after* your SonarQube analysis has completed.

Then, going into your build task, you can adjust further settings.

<img src="https://github.com/emre-aki/tfs-tasks/blob/master/img/task-parameters.png?raw=true" width="800">

Once the build completes, the Quality Gate status regarding your SonarQube project at the respective branch will be reported in the build summary as follows:

<img src="https://github.com/emre-aki/tfs-tasks/blob/master/img/success.png?raw=true" width="400">

or 

<img src="https://github.com/emre-aki/tfs-tasks/blob/master/img/fail.png?raw=true" width="400">
