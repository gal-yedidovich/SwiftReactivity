//
//  Watch.swift
//
//
//  Created by Gal Yedidovich on 15/04/2024.
//

import Foundation

public class Watch<WatchedValue: Hashable> {
	private let id = UUID()
	private let handler: (WatchedValue, WatchedValue) -> Void
	private var currentValue: WatchedValue
	private let reactiveValue: any ReactiveValue<WatchedValue>
	
	public convenience init(
		_ signal: Signal<WatchedValue>,
		handler: @escaping (WatchedValue, WatchedValue) -> Void
	) {
		self.init(value: signal, handler: handler)
	}
	
	public convenience init(
		_ computed: Computed<WatchedValue>,
		handler: @escaping (WatchedValue, WatchedValue) -> Void
	) {
		self.init(value: computed, handler: handler)
	}
	
	public convenience init(
		_ computedHandler: @autoclosure @escaping () -> WatchedValue,
		handler: @escaping (WatchedValue, WatchedValue) -> Void
	) {
		self.init(value: Computed(handler: computedHandler), handler: handler)
	}
	
	private init(value reactiveValue: any ReactiveValue<WatchedValue>, handler: @escaping (WatchedValue, WatchedValue) -> Void) {
		self.handler = handler
		self.currentValue = reactiveValue.value
		self.reactiveValue = reactiveValue
		
		reactiveValue.add(observer: self)
	}
	
	deinit {
		reactiveValue.remove(observer: self)
	}
}

extension Watch: Observer {
	func onNotify(sourceChanged: Bool) {
		guard sourceChanged || shouldTrigger() else { return }
		
		let newValue = reactiveValue.value
		handler(newValue, currentValue)
		currentValue = newValue
	}
	
	private func shouldTrigger() -> Bool {
		return reactiveValue.wasDirty(observer: self)
	}
	
	func add(source: any ReactiveValue) {
		//Ignore, Watch observe only explicit source from initializer
	}
}

extension Watch: Hashable {
	public static func == (lhs: Watch<WatchedValue>, rhs: Watch<WatchedValue>) -> Bool {
		lhs.id == rhs.id
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}
