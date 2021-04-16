<script>
  import CVE from "./components/CVESidebar.svelte";
  function* iter_range(begin, end, step) {
    // Normalize our inputs
    step = step ? step : 1;

    if (typeof end === "undefined") {
      end = begin > 0 ? begin : 0;
      begin = begin < 0 ? begin : 0;
    }

    if (begin == end) {
      return;
    }

    if (begin > end) {
      step = step * -1;
    }

    for (let x = begin; x < end; x += step) {
      yield x;
    }
  }

  export function range(begin, end, step) {
    return Array.from(iter_range(begin, end, step));
  }

  let chooseCVE = {
    name: "",
    status: false,
  };

  const baseURL = "HOST";
  const baseAPIURL = `${baseURL}/api/v0`;
  let promise = Promise.resolve([]);

  let query = "";
  let offset = 30;
  let page = 0;
  let cache = true;

  let max_page = Number.MAX_VALUE;

  // CVEイベントハンドラ
  // 1. パッケージ名からCVEを検索して返してくれるAPIへリクエスト
  // 2. 取得したCVE情報をモーダルあたりで描画。

  // ページングイベントハンドラ

  // 検索イベントハンドラ
  // 初期にも呼ばれる。
  async function searchReq(params) {
    let fetchURL = new URL(`${baseAPIURL}/pkgs`);
    Object.keys(params).forEach((key) =>
      fetchURL.searchParams.append(key, params[key]),
    );

    const resp = await fetch(fetchURL);
    if (resp.ok) {
      return resp.json();
    } else {
      throw new Error("Invalid Response.");
    }
  }
  async function searchReqUseElem() {
    let params = {
      query: query,
      offset: offset,
      page: page,
      cache: cache,
    };
    return searchReq(params);
  }
  function handleMovePage(i) {
    if (page + i < 0 || page + i > max_page) return;
    page = page + i;
    promise = searchReqUseElem();
  }
  function handleSearch() {
    promise = searchReqUseElem();
  }
  // cveハンドラ
  function handlePkgBtnClick(name) {
    chooseCVE.name = name;
    chooseCVE.status = true;
  }
  // 待機イベントハンドラ
  // 検索中みたいなやつだしたい。

  // GETパラメータを読み込む
  // サーバにパラメータをいれてリクエスト
  handleSearch();
</script>

<style>
</style>

{#await promise}
  <p>...waiting</p>
{:then data}
  <div class="wrapper">
    <CVE bind:name={chooseCVE.name} bind:show={chooseCVE.status} />
    <div class="content">
      <p>
        search:
        <input type="text" placeholder="search query" bind:value={query} />
      </p>
      <p>
        offset:
        <input type="number" placeholder="search offset" bind:value={offset} />
      </p>
      <p>
        <button on:click={handleSearch} class="btn btn-primary">Search</button>
      </p>

      {(() => {
        max_page = data.max_page;
        page = data.page;
        return '';
      })()}
      <p>{page + 1} / {data.max_page + 1} 件</p>
      <nav>
        <ul class="pagination">
          <li class="page-item">
            <button
              class="page-link"
              on:click={() => handleMovePage(-1)}>Previous</button>
          </li>
          <li class="page-item">
            <button
              class="page-link"
              on:click={() => handleMovePage(1)}>Next</button>
          </li>
        </ul>
      </nav>
      <table class="table">
        <thead>
          <th>Package Name</th>
          {#each data.srv_names as srv}
            <th>{srv}</th>
          {/each}
        </thead>
        <tbody>
          {#each data.pkg_names as pkg}
            <tr>
              <td>
                <button
                  class="btn btn-outline-primary"
                  on:click={() => handlePkgBtnClick(pkg)}>{pkg}</button>
              </td>
              {#each data.srv_names as srv}
                <td>{data.data[srv][pkg] ?? ''}</td>
              {/each}
            </tr>
          {/each}
        </tbody>
      </table>
      <p>{page + 1} / {data.max_page + 1} 件</p>
      <nav aria-label="Page navigation example">
        <ul class="pagination">
          <li class="page-item">
            <button
              class="page-link"
              on:click={() => handleMovePage(-1)}>Previous</button>
          </li>
          <li class="page-item">
            <button
              class="page-link"
              on:click={() => handleMovePage(1)}>Next</button>
          </li>
        </ul>
      </nav>
    </div>
  </div>
{:catch error}
  <p style="color: red">{error.message}</p>
{/await}
