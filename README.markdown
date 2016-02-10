# Calendar

by [Matt Gemmell](http://mattgemmell.com/)


## What is it?

It's a Ruby script that outputs a monthly calendar, like the `cal` command in Unix, but with more control over the output format.

![Ruby calendar on the command-line](https://c2.staticflickr.com/2/1645/24910965616_bcfe942830_d.jpg)

![Ruby calendar with HTML output](https://c2.staticflickr.com/2/1444/24937234535_d10cd2797c_d.jpg)


## What are its requirements?

Just Ruby itself.


## What does it do?

It generates a monospaced monthly calendar for the command-line, like the `cal` command, but its output can be customised to produce any textual format you like, such as HTML.

Options include specifying the month and/or year, the starting day of the week and how many days to show per week, and whether to generate calendars for a single month, a sequence of three months, or an entire year.

It can use an external configuration file to extensively customise how it renders its output. An example configuration file is included, which will produce an HTML/CSS calendar. It also provides for highlighting the current day, week, and month in a manner of your choosing.

That's about it.


## How do I use it?

Just do `ruby calendar.rb` on the command-line.

You can use the `-h` switch to learn about a few useful options.

The script sends output to Standard Output, which you can of course redirect to wherever you'd like. For example, to send the calendar to a file called `mycal.txt`, you can do `ruby calendar.rb > mycal.txt`.

You can customise the script's behaviour via the configuration file, and command-line options. You shouldn't need to change anything in the script itself.


## What _doesn't_ it do?

That thing you were hoping it did. Any non-Gregorian calendar formats. And anything I've not explicitly said that it _does_ do.


## Who made it?

Matt Gemmell (that's me).

- My website is at [mattgemmell.com](http://mattgemmell.com)

- I'm on Twitter as [@mattgemmell](http://twitter.com/mattgemmell)

- This code is on github at [github.com/mattgemmell/Calendar](http://github.com/mattgemmell/Calendar)


## What license is the code released under?

Creative Commons [Attribution-Sharealike](http://creativecommons.org/licenses/by-sa/4.0/).

If you need a difference license, feel free to ask.


## Why did you make this?

Partly for fun, and partly because the output from `cal` was too inflexible (and visually cramped) for my taste. I also really wanted the ability to highlight the current day, week, and/or month, and to generate an HTML version of the calendar if necessary.

I know there are presumably a million such scripts. Now there's a million and one.


## Can you provide support?

Nope. If you find a bug, please fix it and submit a pull request via github.


## I have a feature request

Feel free to [create an issue](https://github.com/mattgemmell/Calendar/issues) with your idea.


## How can I thank you?

You can:

- [Support my writing](http://mattgemmell.com/support-me/).

- Check out [my Amazon wishlist](http://www.amazon.co.uk/registry/wishlist/1BGIQ6Z8GT06F).

- Say thanks [on Twitter](http://twitter.com/mattgemmell), I suppose.
