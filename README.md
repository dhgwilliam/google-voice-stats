# google-voice-stats

[![Code Climate](https://codeclimate.com/github/dhgwilliam/google-voice-stats.png)](https://codeclimate.com/github/dhgwilliam/google-voice-stats)

## Instructions

0. This app has been developed and tested exclusively on Ruby 1.9.3
0. Install and run [redis](http://redis.io)
    * this app uses redis db 15 because who cares. change this in config.ru if it bugs you
    * please make sure it's a relatively recent version, esp. if you get
      an error about commands being unavailable, like: `ERR unknown command 'hget'`
0. Install `pandoc` from [http://code.google.com/p/pandoc/downloads/list]()
0. Go to [google.com/takeout]() and dump your Google Voice data (including text messages, obviously). Once this is done, download, unzip and continue
1. Navigate to the you@gmail.com-takeout/Voice/Calls folder and move all the .html files (or all files in Calls) to the `google-voice-stats/data` folder
1. `bundle install --binstubs`
2. `bin/rake import`
3. Run `bin/rackup` or `bin/shotgun config.ru` or whatever
4. Open `http://localhost:4567/people`
5. Try visiting `http://localhost:4567/people/2/details`
6. Visit routes.rb for more info


1. [/dictionary/init]()
2. [/dictionary/refreshall]()
2. [/dictionary/refreshall/sips]()

## Roadmap

I plan on messing around with D3 at the PDX Quantified Self meetup next week, so, uh, funsies!

09/17/2012, --dhgwilliam
