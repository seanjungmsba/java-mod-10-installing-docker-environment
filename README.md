# Installing Docker Environment

## Learning Goals

- Practice setting up Docker on a local development machine
- Learn basic usage of Docker for running pre-built applications
- Experience running PostgreSQL as a container
- Understand testing of infrastructure with Chef Inspec

## Instructions

In this lab, we will be running through the process of setting up the Docker Desktop environment on Windows
and Mac computers. For the next few days, we will only be using Docker to simplify the process of running local Database
instances. For now we will stop after getting a pre-built application launched via Docker, but will continue on later in
the week to utilize Docker more.

### Tests

Similar to how testing can be done against an application codebase, we can also apply a similar workflow
to computer infrastructure and systems themselves. This is a much larger topic in general which would pull in areas of
DevOps such as Configuration Management and Infrastructure as Code, but in this case, we will be using this tooling primarily
to test completion of these labs.

We will be using Chef Inspec for these purposes, which is a well supported industry tool. There are a wide array of
infrastructure testing frameworks though, with choice tending to be restricted based on overall tooling stack. You might
see a different testing framework in your own work, or maybe not even need to touch something like this at all in your
daily responsibilities.

### Structure

Now that we are moving from programming to DevOps / Systems Administration type work, the structure of these labs will
be a bit different. As the intent here isn't to train DevOps engineers, but instead familiarize developers
with DevOps practices for a more complete picture of the full software lifecycle, we are approaching these labs as more
of a hands on demo experience, as opposed to implementing anything fully from scratch. Feel free to dive more in depth
anywhere you have interest, but be aware that DevOps can be considered a separate role from Software Engineering,
and take an appropriate amount of time to learn.

## Setting up Docker on a local development machine

We won't dive too much into the inner workings of Docker or containers at this point. So instead, let us just get started with the
installation process. We will be directly following the Docker documentation at [https://docs.docker.com](https://docs.docker.com)
for this. Follow the [Windows](https://docs.docker.com/desktop/windows/install/) or [Mac](https://docs.docker.com/desktop/mac/install/)
guide depending on the development workstation you are using.

Once Docker Desktop has been installed, open up a command prompt and type in the following Docker commands to validate Docker
is working correctly on your computer.

``` shell
docker run hello-world
```

You should see something similar to the below if everything is working properly

``` shell
Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

At this point, we can move on to Postgres.

## Running PostgreSQL as a container

Now that we have the Docker service running locally on a machine, we can use it to setup self-contained applications
very rapidly for testing and local development purposes. In this case, we will be running a local PostgreSQL instance to accommodate further lessons and labs in this module.

Run the following command from a terminal.

``` shell
docker run --name postgres-lab -e POSTGRES_PASSWORD=mysecretpassword -e POSTGRES_DB=db_test -p 5432:5432 -d ubuntu/postgres:14-22.04_beta
```

And after this instance starts, you can remote into the container to run cli commands manually.

``` shell
docker exec -it postgres-lab /bin/bash
root@9d7a283e5eb0:/# psql -U postgres
psql (14.4 (Ubuntu 14.4-0ubuntu0.22.04.1))
Type "help" for help.

postgres=# \l
                                 List of databases
   Name    |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges   
-----------+----------+----------+------------+------------+-----------------------
 db_test   | postgres | UTF8     | en_US.utf8 | en_US.utf8 | 
 postgres  | postgres | UTF8     | en_US.utf8 | en_US.utf8 | 
 template0 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
(4 rows)
```

You now have a fully fledged Database system running locally on your machine that you can interact with like an independent server.
In fact, if you have any other Database Administration tools, you can use those as well.

Try downloading the "Database Navigator" plugin for IntelliJ IDEA, and connect to this DB instance using 127.0.0.1:5432/db_test
as the instance, and postgres/mysecretpassword as the username/password. "Database Navigator" doesn't seem to be a complete DB client
implementation, but it should give you the abilities to inspect the DB and view its state easily.


## Running the Tests

Now that we have an environment up and running, let us see how to run the testing that will be associated with out labs.
As mentioned, we are using Chef Inspec for this, which has a very human readable syntax.
For example, to scan a server to make sure Postgres is configured properly, you can use a check like the below.

``` ruby
describe postgres_conf('/var/lib/postgresql/data/postgresql.conf') do
  its('port') { should eq '5432' }
end
```

In fact, lets scan this container to make sure this Postgres service is running, and has the default user and database in place.

Start by building the testing container. Navigate to the root directory of this lab's git repository, and run the following
commands.

> Note: This is a fairly hacky solution to get infrastructure testing installed onto uncontrolled classroom workstations. If this
> fails to run for any reason, loop in the instructors first before taking on any debugging on your part. 

``` shell
docker build -t inspec-lab -f Dockerfile.Inspec .
docker run -it --rm -v $(pwd)/test:/test inspec-lab
docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd)/test:/test inspec-lab exec postgres.rb -t docker://postgres-lab 

Profile:   tests from postgres.rb (tests from postgres.rb)
Version:   (not specified)
Target:    docker://9d7a283e5eb093e479925532e698b2da80b727598772397aa6650a531cc171f9
Target ID: da39a3ee-5e6b-5b0d-b255-bfef95601890

  ✔  postgres-installed: Postgres: Installed
     ✔  System Package postgresql-14 is expected to be installed
  ✔  postgres-running: Postgres: Running
     ✔  Processes postgres is expected to be running
  ✔  postgres-user: Postgres: User Created
     ✔  PostgreSQL query: SELECT usename FROM pg_catalog.pg_user; output is expected to include "postgres"
  ✔  postgres-db: Postgres: Database Created
     ✔  PostgreSQL query: SELECT datname FROM pg_database; output is expected to include "db_test"


Profile Summary: 4 successful controls, 0 control failures, 0 controls skipped
Test Summary: 4 successful, 0 failures, 0 skipped
```

Try deleting the database now, to see that the tests start failing.

``` shell
docker exec -it postgres-lab /bin/bash
root@9d7a283e5eb0:/# psql -U postgres 
postgres=# DROP DATABASE db_test WITH (FORCE);
DROP DATABASE
```

``` shell
docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd)/test:/test inspec-lab exec postgres.rb -t docker://postgres-lab 

Profile:   tests from postgres.rb (tests from postgres.rb)
Version:   (not specified)
Target:    docker://9d7a283e5eb093e479925532e698b2da80b727598772397aa6650a531cc171f9
Target ID: da39a3ee-5e6b-5b0d-b255-bfef95601890

  ✔  postgres-installed: Postgres: Installed
     ✔  System Package postgresql-14 is expected to be installed
  ✔  postgres-running: Postgres: Running
     ✔  Processes postgres is expected to be running
  ✔  postgres-user: Postgres: User Created
     ✔  PostgreSQL query: SELECT usename FROM pg_catalog.pg_user; output is expected to include "postgres"
  ×  postgres-db: Postgres: Database Created
     ×  PostgreSQL query: SELECT datname FROM pg_database; output is expected to include "db_test"
     expected "postgres\ntemplate1\ntemplate0" to include "db_test"
     Diff:
     @@ -1,3 +1,5 @@
     -db_test
     +postgres
     +template1
     +template0



Profile Summary: 3 successful controls, 1 control failure, 0 controls skipped
Test Summary: 3 successful, 1 failure, 0 skipped
```

Now destroy and recreate the Postgres container, and verify it passes the tests once more.
Rebuilding off of a known working state will allow for very rapid iteration, removing the need for any long lived setups that may accumulate configuration drift.
