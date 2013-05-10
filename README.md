# google-voice-stats

## Instructions

0. This branch includes a Vagrantfile that should automatically configure a Debian 6.0.3/Squeeze box from scratch using Puppet
0. Go to [google.com/takeout]() and dump your Google Voice data (including text messages, obviously). Once this is done, download, unzip and continue
1. Navigate to the you@gmail.com-takeout/Voice/Calls folder and move all the .html files (or all files in Calls) to the `google-voice-stats/data` folder
1. `vagrant up`
1. `vagrant ssh`
2. `sudo -s`
2. `source ~/.profile`
    - this absolutely shouldn't be necessary but I'm too lazy to deal with it right right now
2. the `google-voice-stats/data` folder should be available in `/vagrant/data`. Copy it to `/home/vagrant/src/google-voice-stats/data/`
    - some day I'll streamline this
2. `bin/rake import`
2. `QUEUE=* bin/rake resque:work &`
    - note: you can start more workers this way as well. you probably shouldn't do more than 1 worker per CPU core, right?
3. Run `bin/rackup -p 4567`
4. Open [http://localhost:8080/]() in a browser on your host OS
5. Try visiting [http://localhost:8080/person/2/details]()
6. Review routes.rb for more info

---

Loading the following URLs should intiate a set of processes that will fully
populate your application. I will also simplify this in the future.

1. [http://localhost:8080/dictionary/init]()
2. [http://localhost:8080/dictionary/refreshall]()
2. [http://localhost:8080/dictionary/refreshall/sips]()
