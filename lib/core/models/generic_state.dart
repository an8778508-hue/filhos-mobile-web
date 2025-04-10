import 'package:equatable/equatable.dart';
import 'package:escola/core/errors/failures.dart';

enum RequestType { load, reload, loadMore }

class GenericListState<T> extends Equatable {
  final List<T> data;
  final bool loading;
  final bool reloading;
  final bool loadingMore;
  final bool noMore;
  final int currentPage;
  final Failure? failure;

  const GenericListState({
    this.data = const [],
    this.loading = false,
    this.reloading = false,
    this.loadingMore = false,
    this.noMore = false,
    this.currentPage = 1,
    this.failure,
  });

  GenericListState<T> asLoading() => GenericListState<T>(
        loading: true,
      );

  GenericListState<T> asReloading() => GenericListState<T>(
        reloading: true,
        data: [...data],
        noMore: noMore,
        currentPage: currentPage,
      );

  GenericListState<T> asLoadingMore() => GenericListState<T>(
        loadingMore: true,
        data: [...data],
        noMore: noMore,
        currentPage: currentPage,
      );

  GenericListState<T> asSuccessfullyLoaded(List<T> data) => GenericListState<T>(
        data: [...data],
        noMore: noMore,
      );

  GenericListState<T> asSuccessfullyLoadedMore(List<T> data) => GenericListState<T>(
        data: [...this.data, ...data],
        noMore: data.isEmpty,
        currentPage: currentPage + 1,
      );

  GenericListState<T> asFailed(Failure failure) => GenericListState<T>(
        data: [...data],
        noMore: noMore,
        currentPage: currentPage,
        failure: failure,
      );

  @override
  List<Object?> get props => [
        data,
        loading,
        reloading,
        loadingMore,
        noMore,
        currentPage,
        failure,
      ];
}

class GenericState extends Equatable {
  final bool success;
  final bool loading;
  final Failure? failure;

  const GenericState({
    this.success = false,
    this.loading = false,
    this.failure,
  });

  GenericState asLoading() => const GenericState(
        loading: true,
      );

  GenericState asSuccess() => const GenericState(
        success: true,
      );

  GenericState asFailed(Failure failure) => GenericState(
        failure: failure,
      );

  @override
  List<Object?> get props => [
        success,
        loading,
        failure,
      ];
}

class GenericDataState<T> extends Equatable {
  final T? data;
  final bool loading;
  final Failure? failure;

  const GenericDataState({
    this.data,
    this.loading = false,
    this.failure,
  });

  GenericDataState<T> asLoading() => GenericDataState<T>(
        loading: true,
      );

  GenericDataState<T> asSuccess(T data) => GenericDataState<T>(
        data: data,
      );

  GenericDataState<T> asFailed(Failure failure) => GenericDataState<T>(
        failure: failure,
      );

  @override
  List<Object?> get props => [
        data,
        loading,
        failure,
      ];
}
