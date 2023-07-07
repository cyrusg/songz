# Songz

This document describes an implementation (or two) of a light-weight song finder based on the Genius API. Its format is slightly different than standard README files since I'm using it to provide a detailed explanation of my observations, assumptions, and design decisions.

## Overview
I began by reviewing the Genius API and playing around with it for a bit to see what it can do. One immediate thing I noticed about the `/search` API was that this endpoint is not speficially designed to return songs belonging to a particular artist; it returns all songs that match the query string. There's an endpoint for returning songs from a particular artist but you have to know the ID of the artist.

Based on the above observations, I realized that our app needs to page through all the results and leave out any songs that don't actually belong to the artist we're interested in. This means that we have to do some sort of text matching ourselves.

### Decisions
- To keep things simple, I decided to fire up a Rails 7 API-only project. Sinatra was a lighter option but I haven't played with it for 2-3 years so I chose the quicker route (no pun intended :).
- I was also hoping to add a Redis instance to provide some cacheing but never got around to it. Please see my notes on the **UrlCacheable** concern below.
- Instead of ENV vars for sensitive data, I wanted to experiment with the Rails Credentials capabilities and used this opportunity to do so. Please see my reference to this in the **Setup** section.

### Wait, there's a gem!
While working on the design described above I ran into the `genius` gem by Tom Rogers and decided to have a look. The gem is somewhat old but really well designed, so I thought it might be a good learning experience to fork and modify it. So, this project has two implementations, one that uses the forked gem (v1) and one that is my own bare bones implementation (v2). Please see the **Usage** section on how to access each implementation.

You can check out the forked gem here: https://github.com/cyrusg/genius.

### UrlCacheable
In doing prior API integration work, I found it useful to cache API call results if the data we are looking for is not of a live nature. The way I've done this is to combine the HTTP method and endpoint url as an expirable *key*, and attach the results as the *value* in Redis. The expiry on each key can be different and set as an absolute date/time or a time duration. This allows us to - for example - expire all keys at midnight so stale data is not served after it is updated by the API provider. 

Unfortunately I didn't get a chance to implement that in this project, but I think it can benefit from something like it.

### Assignment Discussion

##### What can go wrong when interacting with the API?
0. There's always the standard 401, 403, and 404 issues.
1. They do raise 422's when bad params are passed in.
2. The phrase "rate limit" or the word "limit" is nowhere in the docs, so I'm sure unmanaged contention is a definite issue that can easily come up.
3. TTIMEOUT errors can occur, most-likely due to the #2 above, or maybe even from their side when actual queries they make don't come back on time.

##### What level of unit tests should you write?
In working with this API, I came to the conclusion that there may be value in writing some tests that are live. The gem comes with what seems to be a comprehensive set of unit "static" tests which are done using VCR. So my short answer here is this:
- do a thorough job writing cases with VCR that give us decent code coverage, but
- let's throw in a few live API calls... this is how I happen to run into the `per_page` issue described below (two questions down).

##### How can your implementation change if we were to change requirements?
The implementation involving the gem (v1) could potentially give us a lot that we can work with (or use as a starting point) when requirements change. My own bare bones implementation (v2) really has very little code in comparison. 

The v2 implementation separates business logic from actual API integration; we should be able to focus on updating the business logic without worrying about updating the API integration itself. For example, I've implemented a `find_by_artist` method in the *Songs* module that attempts to clean up the deluge of search results coming back from the API. The logic there can be easily changed.

##### This is a well behaved API. What if the API wasn’t so well behaved?
I'm not sure how well-behaved this API is. This is what happened when I searched for my last name 'ghalambor', with `per_page` set to 50, three times in a rown within a span of a couple of minutes:
```
Started GET "/api/v1/songs/search?artist=ghalambor&per_page=50" for ::1 at 2023-07-05 11:31:52 -0700
Processing by Api::V1::SongsController#search as HTML
  Parameters: {"artist"=>"ghalambor", "per_page"=>"50"}
page 1 had 19 results.
page 2 had 18 results.
page 3 had 0 results.
Completed 200 OK in 2418ms (Views: 9.7ms | ActiveRecord: 0.0ms | Allocations: 24178)

Started GET "/api/v1/songs/search?artist=ghalambor&per_page=50" for ::1 at 2023-07-05 11:33:05 -0700
Processing by Api::V1::SongsController#search as HTML
  Parameters: {"artist"=>"ghalambor", "per_page"=>"50"}
page 1 had 19 results.
page 2 had 20 results.
page 3 had 3 results.
page 4 had 0 results.
Completed 200 OK in 3329ms (Views: 10.3ms | ActiveRecord: 0.0ms | Allocations: 24961)

Started GET "/api/v1/songs/search?artist=ghalambor&per_page=50" for ::1 at 2023-07-05 11:33:22 -0700
Processing by Api::V1::SongsController#search as HTML
  Parameters: {"artist"=>"ghalambor", "per_page"=>"50"}
page 1 had 19 results.
page 2 had 20 results.
page 3 had 14 results.
page 4 had 0 results.
```

As we can see, the API is not behaving the same way each time (within seconds of being called). Once we see behavior like this, we have to make the minimum, and most conservative assumptions about the response. In this case, we can't assume that a count < 20 signals the end of the pagination loop. We have to keep going until the response containing no results.

A related irony is that the documentation says the max `per_page` value is 50. But in reality the API never returns more than 20 results. We just need to never count on a particular value to make any decisions in code.

# Setup
- Grab the repo at https://github.com/cyrusg/songz.
- The Genius API token is stored in the Rails credentials (development) file to which you should have access. I don't anticipate any issues with the setup in this regard.
- Finally,
`$ bundle update`
`$ bundle exec rails server`

# Usage
If you want to see the modified gem in action:
`/api/v1/search?artist=xxx`

If you want to see the my bare bones API integration and artist search in action:
`/api/v2/search?artist=xxx`
