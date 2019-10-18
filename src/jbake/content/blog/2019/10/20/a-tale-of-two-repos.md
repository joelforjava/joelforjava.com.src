title=A Tale of Two Git Repos
date=2019-10-20
type=post
tags=kafka,kinesis,aws,kafka connect,java,github,git
status=published
~~~~~~

When I started out writing the series of articles regarding Kafka Connect and the Kafka Kinesis Connector, I originally forked the one from AWSLabs and I used that fork for all my modifications and originally intended to use it for all of my articles. However, as I progressed through writing them, I realized I might want to submit some of those things for a pull request to the original repo. I didn't want to add the mess of the YAML and multiple destinations to their code. I didn't want to taint their codebase. So, I made a complete copy of that fork and put it into a new repository so that I could continue to do my articles and experimentations with multiple destinations, etc. I'll eventually yank all of my changes out of my fork and only submit the things I hope others would find useful, such as the config validations.

So if you're ever looking through my github repos and see the two Kafka Kinesis Connector repositories, there's the logic behind them. I apologize if it has caused any confusion.