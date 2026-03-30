module RateLimit exposing
    ( RateLimitKey(..)
    , SendMessageRateLimits
    , checkAndUpdateRateLimit
    , empty
    , maxMessagesPerWindow
    , windowDuration
    )

import Discord
import Duration exposing (Duration)
import Effect.Time as Time
import Id exposing (Id, UserId)
import SeqDict exposing (SeqDict)


type RateLimitKey
    = NormalUserKey (Id UserId)
    | DiscordUserKey (Discord.Id Discord.UserId)


type alias SendMessageRateLimits =
    SeqDict RateLimitKey (List Time.Posix)


empty : SendMessageRateLimits
empty =
    SeqDict.empty


maxMessagesPerWindow : Int
maxMessagesPerWindow =
    20


windowDuration : Duration
windowDuration =
    Duration.seconds 10


checkAndUpdateRateLimit : Time.Posix -> RateLimitKey -> SendMessageRateLimits -> Result SendMessageRateLimits SendMessageRateLimits
checkAndUpdateRateLimit now key limits =
    let
        windowStart : Int
        windowStart =
            Time.posixToMillis now - round (Duration.inMilliseconds windowDuration)

        recentMessages : List Time.Posix
        recentMessages =
            SeqDict.get key limits
                |> Maybe.withDefault []
                |> List.filter (\t -> Time.posixToMillis t > windowStart)
    in
    if List.length recentMessages >= maxMessagesPerWindow then
        Err (SeqDict.insert key recentMessages limits)

    else
        Ok (SeqDict.insert key (now :: recentMessages) limits)
