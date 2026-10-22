import { webview } from '@kit.ArkWeb';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { AppConfig } from '../services/AppConfig';
import { NotificationService } from '../services/NotificationService';
import { BackgroundKeepAlive } from '../services/BackgroundKeepAlive';
import { DownloadService } from '../services/DownloadService';

class TavernNativeBridge {
  private onStart: () => void;
  private onFinish: (preview: string) => void;
  private onStop: () => void;

  constructor(onStart: () => void, onFinish: (preview: string) => void, onStop: () => void) {
    this.onStart = onStart;
    this.onFinish = onFinish;
    this.onStop = onStop;
  }

  generationStarted(): string {
    this.onStart();
    return 'ok';
  }

  generationFinished(preview: string): string {
    this.onFinish(preview || '');
    return 'ok';
  }

  generationStopped(): string {
    this.onStop();
    return 'ok';
  }
}

@Entry
@Component
struct Index {
  private controller: webview.WebviewController = new webview.WebviewController();
  private notification?: NotificationService;
  private keepAlive?: BackgroundKeepAlive;
  private downloadService?: DownloadService;
  private hostContext?: common.UIAbilityContext;

  @State pageTitle: string = 'SillyTavern';
  @State loadingProgress: number = 0;
  @State generationActive: boolean = false;

  private bridge: TavernNativeBridge = new TavernNativeBridge(
    () => this.handleGenerationStarted(),
    (preview: string) => this.handleGenerationFinished(preview),
    () => this.handleGenerationStopped(),
  );

  aboutToAppear(): void {
    const ctx = this.getUIContext().getHostContext();
    if (ctx) {
      this.hostContext = ctx as common.UIAbilityContext;
      this.notification = new NotificationService(this.hostContext);
      this.keepAlive = new BackgroundKeepAlive(this.hostContext);
      this.downloadService = new DownloadService(this.controller, this.hostContext);
    }
  }

  private async initNativeServices(): Promise<void> {
    await this.notification?.init();
    try {
      this.downloadService?.attach();
    } catch (err) {
      const e = err as BusinessError;
      console.error(`attach download delegate failed: ${e.code} ${e.message}`);
    }
  }

  private handleGenerationStarted(): void {
    this.generationActive = true;
    this.keepAlive?.startForGeneration();
  }

  private async handleGenerationFinished(preview: string): Promise<void> {
    this.generationActive = false;
    // 先发完成提醒，再结束长时任务。
    await this.notification?.publishReplyFinished(preview);
    await this.keepAlive?.stop();
  }

  private async handleGenerationStopped(): Promise<void> {
    this.generationActive = false;
    await this.keepAlive?.stop();
  }

  private injectSillyTavernHook(): void {
    const script: string = `
(() => {
  if (window.__HarmonyTavernHookInstalled) return 'already-installed';

  const install = () => {
    try {
      const st = window.SillyTavern;
      const ctx = st && typeof st.getContext === 'function' ? st.getContext() : null;
      if (!ctx || !ctx.eventSource || !ctx.event_types || !window.${AppConfig.BRIDGE_NAME}) {
        setTimeout(install, 800);
        return;
      }

      window.__HarmonyTavernHookInstalled = true;
      const es = ctx.eventSource;
      const ev = ctx.event_types;
      let completedThisTurn = false;

      const preview = () => {
        try {
          const chat = ctx.chat || [];
          const last = chat.length ? chat[chat.length - 1] : null;
          const text = last && typeof last.mes === 'string' ? last.mes : '';
          return text.replace(/<[^>]*>/g, '').replace(/\\s+/g, ' ').slice(0, 120);
        } catch (_) {
          return '';
        }
      };

      if (ev.GENERATION_STARTED) {
        es.on(ev.GENERATION_STARTED, () => {
          completedThisTurn = false;
          try { window.${AppConfig.BRIDGE_NAME}.generationStarted(); } catch (_) {}
        });
      }

      const notifyDone = () => {
        if (completedThisTurn) return;
        completedThisTurn = true;
        try { window.${AppConfig.BRIDGE_NAME}.generationFinished(preview()); } catch (_) {}
      };

      if (ev.GENERATION_ENDED) {
        es.on(ev.GENERATION_ENDED, notifyDone);
      } else if (ev.MESSAGE_RECEIVED) {
        es.on(ev.MESSAGE_RECEIVED, notifyDone);
      }

      if (ev.GENERATION_STOPPED) {
        es.on(ev.GENERATION_STOPPED, () => {
          try { window.${AppConfig.BRIDGE_NAME}.generationStopped(); } catch (_) {}
        });
      }
      return 'installed';
    } catch (_) {
      setTimeout(install, 1000);
    }
  };

  install();
  return 'installing';
})();`;

    this.controller.runJavaScript(script).then((result: string) => {
      console.info(`SillyTavern hook: ${result}`);
    }).catch((err: BusinessError) => {
      console.error(`inject hook failed: ${err.code} ${err.message}`);
    });
  }

  private clearWebData(): void {
    try {
      this.controller.removeCache(true);
    } catch (err) {
      const e = err as BusinessError;
      console.warn(`removeCache failed: ${e.code} ${e.message}`);
    }

    const clearScript = `
      try { localStorage.clear(); } catch (_) {}
      try { sessionStorage.clear(); } catch (_) {}
      'cleared';`;
    this.controller.runJavaScript(clearScript).finally(() => {
      this.controller.refresh();
      promptAction.showToast({ message: '已清理网页缓存与本地存储' });
    });
  }

  build() {
    Column() {
      Row() {
        Button('‹')
          .fontSize(24)
          .width(48)
          .onClick(() => {
            try { if (this.controller.accessBackward()) this.controller.backward(); } catch (_) {}
          })

        Button('›')
          .fontSize(24)
          .width(48)
          .onClick(() => {
            try { if (this.controller.accessForward()) this.controller.forward(); } catch (_) {}
          })

        Button('↻')
          .width(48)
          .onClick(() => this.controller.refresh())

        Button('首页')
          .onClick(() => this.controller.loadUrl(AppConfig.HOME_URL))

        Text(this.generationActive ? 'AI生成中…' : this.pageTitle)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)

        Button('清理')
          .onClick(() => this.clearWebData())
      }
      .height(52)
      .width('100%')
      .padding({ left: 6, right: 6 })

      if (this.loadingProgress > 0 && this.loadingProgress < 100) {
        Progress({ value: this.loadingProgress, total: 100, type: ProgressType.Linear })
          .width('100%')
          .height(2)
      }

      Web({ src: AppConfig.HOME_URL, controller: this.controller })
        .width('100%')
        .layoutWeight(1)
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .fileAccess(true)
        .zoomAccess(true)
        .multiWindowAccess(true)
        .mixedMode(MixedMode.All)
        // H5 <input type="file">：返回 false，交给 ArkWeb 默认文件选择弹窗处理。
        // SillyTavern 的角色卡、预设、世界书等导入入口可直接调用系统选择器。
        .onShowFileSelector(() => false)
        .javaScriptProxy({
          object: this.bridge,
          name: AppConfig.BRIDGE_NAME,
          methodList: ['generationStarted', 'generationFinished', 'generationStopped'],
          controller: this.controller,
        })
        .onControllerAttached(() => {
          this.initNativeServices();
        })
        .onProgressChange((event) => {
          this.loadingProgress = event?.newProgress ?? 0;
        })
        .onTitleReceive((event) => {
          if (event?.title) this.pageTitle = event.title;
        })
        .onPageEnd(() => {
          this.injectSillyTavernHook();
        })
        .onRenderExited(() => {
          // ArkWeb 渲染进程异常退出时自动恢复首页。
          setTimeout(() => this.controller.loadUrl(AppConfig.HOME_URL), 300);
        })
    }
    .width('100%')
    .height('100%')
  }
}
