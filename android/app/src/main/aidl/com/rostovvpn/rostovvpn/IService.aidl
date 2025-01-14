package com.rostovvpn.rostovvpn;

import com.rostovvpn.rostovvpn.IServiceCallback;

interface IService {
  int getStatus();
  void registerCallback(in IServiceCallback callback);
  oneway void unregisterCallback(in IServiceCallback callback);
}