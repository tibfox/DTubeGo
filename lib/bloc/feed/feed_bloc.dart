import 'package:bloc/bloc.dart';
import 'package:dtube_go/bloc/feed/feed_state.dart';
import 'package:dtube_go/bloc/feed/feed_event.dart';
import 'package:dtube_go/bloc/feed/feed_response_model.dart';
import 'package:dtube_go/bloc/feed/feed_repository.dart';
import 'package:dtube_go/utils/SecureStorage.dart' as sec;

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  FeedRepository repository;
  bool isFetching = false;

  FeedBloc({required this.repository}) : super(FeedInitialState());

  @override
  Stream<FeedState> mapEventToState(FeedEvent event) async* {
    String _avalonApiNode = await sec.getNode();
    String? _applicationUser = await sec.getUsername();
    // event to reset the feed state
    if (event is InitFeedEvent) {
      yield FeedInitialState();
    }
    // event to fetch moments
    if (event is FetchMomentsEvent) {
      String _tsRangeFilter = '&tsrange=' +
          (DateTime.now().add(Duration(days: -14)).millisecondsSinceEpoch /
                  1000)
              .toString() +
          ',' +
          (DateTime.now().millisecondsSinceEpoch / 1000).toString();

      yield FeedLoadingState();
      try {
        List<FeedItem> feed = event.feedType == "NewMoments"
            ? await repository.getNewFeedFiltered(
                _avalonApiNode,
                "&authors=all,%5Es3rk47&tags=DTubeGo-Moments",
                _tsRangeFilter,
                _applicationUser)
            : await repository.getMyFeedFiltered(_avalonApiNode,
                "&tags=DTubeGo-Moments", _tsRangeFilter, _applicationUser);
        yield FeedLoadedState(feed: feed, feedType: event.feedType);
      } catch (e) {
        print(e.toString());
        yield FeedErrorState(message: e.toString());
      }
    }
// event to fetch user moments
    if (event is FetchMomentsOfUserEvent) {
      String _tsRangeFilter = '&tsrange=' +
          (DateTime.now().add(Duration(days: -90)).millisecondsSinceEpoch /
                  1000)
              .toString() +
          ',' +
          (DateTime.now().millisecondsSinceEpoch / 1000).toString();

      yield FeedLoadingState();
      try {
        List<FeedItem> feed = event.feedType == "NewUserMoments"
            ? await repository.getNewFeedFiltered(
                _avalonApiNode,
                "&authors=" + event.username + "&tags=DTubeGo-Moments",
                _tsRangeFilter,
                _applicationUser)
            : await repository.getMyFeedFiltered(_avalonApiNode,
                "&tags=DTubeGo-Moments", _tsRangeFilter, _applicationUser);
        yield FeedLoadedState(feed: feed, feedType: event.feedType);
      } catch (e) {
        print(e.toString());
        yield FeedErrorState(message: e.toString());
      }
    }

    // even to fetch tag list entries of the last 90 days
    if (event is FetchTagSearchResults) {
      String _tsRangeFilter = '&tsrange=' +
          (DateTime.now().add(Duration(days: -90)).millisecondsSinceEpoch /
                  1000)
              .toString() +
          ',' +
          (DateTime.now().millisecondsSinceEpoch / 1000).toString();

      yield FeedLoadingState();
      try {
        List<FeedItem> feed = await repository.getNewFeedFiltered(
            _avalonApiNode,
            "&tags=" + event.tags,
            _tsRangeFilter,
            _applicationUser);
        yield FeedLoadedState(feed: feed, feedType: "tagSearch");
      } catch (e) {
        print(e.toString());
        yield FeedErrorState(message: e.toString());
      }
    }
    // event to fetch posts of a specific feed
    if (event is FetchFeedEvent) {
      print("FETCH " + event.feedType);
      yield FeedLoadingState();
      try {
        List<FeedItem> feed = [];
        switch (event.feedType) {
          case 'MyFeed':
            {
              feed = await repository.getMyFeed(_avalonApiNode,
                  _applicationUser, event.fromAuthor, event.fromLink);
            }
            break;
          case 'HotFeed':
            {
              feed = await repository.getHotFeed(_avalonApiNode,
                  event.fromAuthor, event.fromLink, _applicationUser);
            }
            break;
          case 'TrendingFeed':
            {
              feed = await repository.getTrendingFeed(_avalonApiNode,
                  event.fromAuthor, event.fromLink, _applicationUser);
            }
            break;
          case 'NewFeed':
            {
              feed = await repository.getNewFeed(_avalonApiNode,
                  event.fromAuthor, event.fromLink, _applicationUser);
            }
            break;
        }

        yield FeedLoadedState(feed: feed, feedType: event.feedType);
      } catch (e) {
        yield FeedErrorState(message: e.toString());
      }
    }
    // event to fetch videos of a specific user
    if (event is FetchUserFeedEvent) {
      yield FeedLoadingState();
      try {
        List<FeedItem> feed = await repository.getNewFeedFiltered(
            _avalonApiNode,
            "&authors=" + event.username + "&tags=all,%5EDTubeGo-Moments",
            "" // tsrange currently not used here to load all uploads of the user
            ,
            _applicationUser);
        yield FeedLoadedState(feed: feed, feedType: "UserFeed");
      } catch (e) {
        print(e.toString());
        yield FeedErrorState(message: e.toString());
      }
    }
  }
}
