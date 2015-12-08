# Git Time Turner
Have you ever wanted to turn time like Hermione Granger. Well now you can with git!

## Disclaimer:
Do not use this tool if you are working with a team as it is generally frowned upon to modify git history because new hashes are generated when you change the date. **You will also lose your tags**.


## Installation
```bash cd git-time-turner && ./install.sh```

## Moving commits
After git time-turner is installed you will want to change the date of some of your commits. You can change a range of commits or just a single commit.

### Changing the date of range of commits
If you have a range of commits from ```ebf89``` to ```cf98c``` that you want to move the date forward by 5 minutes then you can just run:
```bash git turn-time -c ebf89..cf98c -t 5h```

### Changing the date of a single commit
If you have single commit ```ec9fd``` that you want to move the date backward by 4 days then run:
```bash git turn-time -c ec9fd -t -4d```

## Usage
After git-time-turner has been installed all you need to do is run ```git turn-time [OPTIONS]```.

### Options

#### -t, --time=VALUE[UNIT]

 Specify the amount of time that you want to travel. You can specify a unit if you want to use a unit other than seconds. The UNITs are:
* d for days
* h for hours
* m for minutes
* s for seconds

#### -c, --commits=[revision [range]]

The revision or revision range that you would like to shift the dates for. Revision ranges are inclusive. 

##### Single revision:

HEAD

##### Revision range:

origin..HEAD
